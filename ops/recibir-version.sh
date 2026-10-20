#!/bin/bash
# Recibir una versión nueva de Wazuh SIN romper lo que funciona. Un solo comando, siempre el mismo orden:
#   0) comprobaciones previas: el stack actual en VERDE, disco con margen, versión que nuestra capa traductora
#      sabe leer, y mismo motor OpenSearch en indexer y dashboard (si cambia, sus datos se migran y ya no hay
#      vuelta atrás automática: eso se planifica a mano, nunca por aquí)
#   1) copia de seguridad: compose + etiqueta <tag>-pre-<fecha> de cada imagen en uso
#   2) construye nuestras imágenes candidatas sobre la versión nueva (desde /opt/triplesoc/src)
#   3) canario + set de oro con las candidatas → si algo falla, se para SIN tocar el stack
#   4) (solo con --promover) promociona en el orden de Wazuh: indexer → manager → dashboard
#   5) verificación en vivo: contenedores sanos, alertas nuevas llegando y upgrade-check VERDE
#      → si algo falla, VUELVE SOLO a las imágenes anteriores y lo deja escrito en el informe
#
# Uso (en el servidor, como root):
#   ops/recibir-version.sh probar 4.14.9      → pasos 0-3. No toca el stack. Deja las candidatas listas.
#   ops/recibir-version.sh promover 4.14.9    → pasos 0-5.
#   ops/recibir-version.sh ensayo             → simulacro: "promociona" las MISMAS imágenes y fuerza la vuelta
#                                               atrás, para demostrar que el camino de rollback funciona.
#   Mejor en segundo plano, porque la terminal de Coolify se corta:
#   nohup ops/recibir-version.sh promover 4.14.9 >/dev/null 2>&1 &   (informe en /opt/triplesoc/releases/)
# Variables: COMPONENTES="indexer manager dashboard", NEED_GB=10 (espacio que necesita una versión nueva),
#            DISK_MAX=80 (% de disco que no se puede superar), SID.
# Códigos de salida: 0 VERDE · 1 ROJO sin cambios en el stack · 2 vuelta atrás hecha · 3 vuelta atrás FALLIDA.
#
# La promoción re-etiqueta: la etiqueta que usa el compose (p. ej. triplesoc/wazuh-manager:4.14.7) pasa a
# apuntar a la imagen nueva. Así el compose guardado en Coolify no cambia y un "Restart" desde Coolify sigue
# arrancando la versión promocionada. La versión real queda en /opt/triplesoc/releases/ACTUAL.
MODE=${1:-}; V=${2:-}
SID=${SID:-yf8u7icjiq4vdhetmea7rmfr}
SVC_DIR=/data/coolify/services/$SID
CMP=$SVC_DIR/docker-compose.yml
SRC=$(cd "$(dirname "$0")/.." && pwd)
COMPONENTES=${COMPONENTES:-indexer manager dashboard}
NEED_GB=${NEED_GB:-10}; DISK_MAX=${DISK_MAX:-80}
STAMP=$(date -u +%Y%m%d-%H%M)
OUT=/opt/triplesoc/releases/$STAMP-${MODE:-x}${V:+-$V}
LOCK=/run/triplesoc-release.lock

case "$MODE" in
  probar|promover) [[ "$V" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "uso: $0 probar|promover X.Y.Z  ·  $0 ensayo"; exit 1; } ;;
  ensayo) V=actual ;;
  *) echo "uso: $0 probar|promover X.Y.Z  ·  $0 ensayo"; exit 1 ;;
esac
[ "$(id -u)" = 0 ] || { echo "ejecutar como root"; exit 1; }
mkdir -p "$OUT" && chmod 700 /opt/triplesoc/releases "$OUT"
exec 9>"$LOCK"; flock -n 9 || { echo "ya hay otra recepción de versión en marcha"; exit 1; }
exec > >(tee -a "$OUT/informe.log") 2>&1

ok()   { printf '  OK    %s\n' "$*"; }
info() { printf '  ...   %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; }
sec()  { printf '\n[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }
svc()  { echo "wazuh-$1"; }                                     # servicio del compose
ctr()  { echo "wazuh-$1-$SID"; }                                # contenedor
tag_of() { grep -A1 -E "^  $(svc "$1"):$" "$CMP" | grep -oE "image: '[^']+'" | cut -d"'" -f2; }
repo_of() { local t; t=$(tag_of "$1"); echo "${t%:*}"; }
id_of() { docker image inspect -f '{{.Id}}' "$1" 2>/dev/null | cut -c8-19; }
disk_pct() { df -P / | awk 'NR==2{gsub("%","",$5); print $5}'; }
engine() {  # versión del motor de datos (OpenSearch) dentro de una imagen; vacío si no aplica
  case "$1" in
    indexer)   docker run --rm --network none --entrypoint sh "$2" -c 'ls /usr/share/wazuh-indexer/lib' 2>/dev/null | grep -oE '^opensearch-[0-9.]+[0-9]' | head -1 ;;
    dashboard) docker run --rm --network none --entrypoint sh "$2" -c 'grep -m1 "\"version\"" /usr/share/wazuh-dashboard/package.json' 2>/dev/null | grep -oE '[0-9.]+[0-9]' ;;
  esac
}
q() { docker exec "$(ctr indexer)" curl -sk --max-time 15 --cert /usr/share/wazuh-indexer/config/certs/admin.pem \
        --key /usr/share/wazuh-indexer/config/certs/admin-key.pem "https://localhost:9200/$1" "${@:2}" 2>/dev/null; }
up_svc() { ( cd "$SVC_DIR" && docker compose --env-file .env -p "$SID" up -d --no-deps --force-recreate "$(svc "$1")" ) >>"$OUT/compose.log" 2>&1; }
wait_healthy() {  # hasta 10 min por contenedor
  local c s i; c=$(ctr "$1")
  for i in $(seq 1 120); do
    s=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$c" 2>/dev/null)
    [ "$s" = healthy ] && return 0
    sleep 5
  done
  echo "    estado de $c: ${s:-no existe}"; return 1
}

echo "TripleSOC · recibir versión · modo $MODE · versión $V · $(date -u '+%F %T') UTC"
echo "  componentes: $COMPONENTES · informe: $OUT"

# ------------------------------------------------------------------ 0. comprobaciones previas
sec "0. Comprobaciones previas"
PRE_FAIL=0
for k in $COMPONENTES; do
  t=$(tag_of "$k"); [ -n "$t" ] && docker image inspect "$t" >/dev/null 2>&1 \
    && ok "$k en uso: $t ($(id_of "$t"))" || { fail "$k: no encuentro su imagen en el compose"; PRE_FAIL=1; }
done
if bash "$SRC/ops/upgrade-check.sh" > "$OUT/check-antes.log" 2>&1; then ok "el stack actual está en VERDE (no se actualiza un sistema que ya falla)"
else fail "el stack actual NO está en VERDE: arreglar primero (ver check-antes.log)"; PRE_FAIL=1; fi
if [ "$MODE" != ensayo ]; then
  read -r size used <<<"$(df -P -BG / | awk 'NR==2{gsub("G","",$2); gsub("G","",$3); print $2, $3}')"
  after=$(( (used + NEED_GB) * 100 / size ))
  [ "$after" -le "$DISK_MAX" ] && ok "disco: ${used}/${size} GB; con la versión nueva quedaría al ${after} % (máx. ${DISK_MAX} %)" \
    || { fail "disco: ${used}/${size} GB; con la versión nueva quedaría al ${after} % (máx. ${DISK_MAX} %). Al 90 % OpenSearch bloquea los índices: ampliar el disco"; PRE_FAIL=1; }
  adapter=$(grep -oE '"adapter"[^"]*"[^"]+"' "$SRC/schema/triplesoc-schema.json" | grep -oE 'wazuh-[0-9]+' | head -1)
  [ "$adapter" = "wazuh-${V%%.*}" ] && ok "la capa traductora sabe leer Wazuh ${V%%.*}.x ($adapter)" \
    || { fail "la capa traductora es $adapter y la versión es ${V%%.*}.x: hace falta su traductor antes de recibirla"; PRE_FAIL=1; }
fi
[ "$PRE_FAIL" = 0 ] || { echo; echo "RESULTADO: ROJO · no se ha tocado nada"; exit 1; }

# ------------------------------------------------------------------ 1. copia de seguridad
sec "1. Copia de seguridad"
cp -p "$CMP" "$OUT/docker-compose.antes.yml" && chmod 600 "$OUT/docker-compose.antes.yml"
: > "$OUT/imagenes-antes.txt"
declare -A TAG BKP
for k in $COMPONENTES; do
  TAG[$k]=$(tag_of "$k"); BKP[$k]="${TAG[$k]}-pre-$STAMP"
  docker tag "${TAG[$k]}" "${BKP[$k]}" && echo "$k ${TAG[$k]} $(id_of "${TAG[$k]}") ${BKP[$k]}" >> "$OUT/imagenes-antes.txt" \
    && ok "$k → ${BKP[$k]}" || { fail "no pude etiquetar la copia de $k"; echo "RESULTADO: ROJO · no se ha tocado nada"; exit 1; }
done

# ------------------------------------------------------------------ 2. candidatas
sec "2. Imágenes candidatas"
declare -A CAND
cleanup_cands() { [ "$MODE" = ensayo ] && return; for k in $COMPONENTES; do docker rmi "${CAND[$k]}" >/dev/null 2>&1; done; }
for k in $COMPONENTES; do
  if [ "$MODE" = ensayo ]; then CAND[$k]=${TAG[$k]}; ok "$k: simulacro con la misma imagen (${TAG[$k]})"; continue; fi
  CAND[$k]="$(repo_of "$k")-cand:$V"
  info "construyendo ${CAND[$k]} (log en build-$k.log)"
  if ( cd "$SRC/triplesoc-$k" && IMAGE="$(repo_of "$k")-cand" bash build.sh "$V" ) > "$OUT/build-$k.log" 2>&1 \
     && docker image inspect "${CAND[$k]}" >/dev/null 2>&1; then ok "$k: ${CAND[$k]} ($(id_of "${CAND[$k]}"))"
  else fail "$k: la construcción falló (build-$k.log)"; cleanup_cands; echo "RESULTADO: ROJO · no se ha tocado nada"; exit 1; fi
  p=$(disk_pct); [ "$p" -lt 85 ] || { fail "disco al $p % tras construir $k: paro y libero las candidatas"; cleanup_cands; echo "RESULTADO: ROJO · no se ha tocado nada"; exit 1; }
done
for k in indexer dashboard; do
  case " $COMPONENTES " in *" $k "*) ;; *) continue;; esac
  a=$(engine "$k" "${TAG[$k]}"); b=$(engine "$k" "${CAND[$k]}")
  if [ -n "$a" ] && [ "$a" = "$b" ]; then ok "$k: mismo motor de datos ($a) → la vuelta atrás es segura"
  else fail "$k: el motor cambia (${a:-?} → ${b:-?}). Migra los datos y no tiene vuelta atrás automática: planificar a mano"
       cleanup_cands; echo "RESULTADO: ROJO · no se ha tocado nada"; exit 1; fi
done

# ------------------------------------------------------------------ 3. canario + set de oro
sec "3. Canario y set de oro"
cm=$(tag_of manager); cd_=$(tag_of dashboard)
case " $COMPONENTES " in *" manager "*) cm=${CAND[manager]};; esac
case " $COMPONENTES " in *" dashboard "*) cd_=${CAND[dashboard]};; esac
if MGR="$cm" DSH="$cd_" bash "$SRC/ops/canary.sh" > "$OUT/canario.log" 2>&1; then
  ok "canario VERDE ($(grep -c '  OK ' "$OUT/canario.log") comprobaciones: reglas, dashboard, servicios, set de oro)"
else
  fail "canario ROJO:"; grep '  FAIL' "$OUT/canario.log" | sed 's/^/    /'
  cleanup_cands; echo; echo "RESULTADO: ROJO · no se ha tocado nada"; exit 1
fi
if [ "$MODE" = probar ]; then
  echo; echo "RESULTADO: VERDE · candidatas listas, el stack sigue igual. Para aplicarla: $0 promover $V"; exit 0
fi

# ------------------------------------------------------------------ 4. promoción
PROMOTED=()
rollback() {
  sec "VUELTA ATRÁS: $1"
  local rc=0 k i
  for (( i=${#PROMOTED[@]}-1; i>=0; i-- )); do
    k=${PROMOTED[$i]}
    docker tag "${BKP[$k]}" "${TAG[$k]}" && up_svc "$k" && wait_healthy "$k" \
      && ok "$k de vuelta en $(id_of "${TAG[$k]}")" || { fail "$k NO ha vuelto: revisar a mano (copia en ${BKP[$k]})"; rc=1; }
  done
  if [ "$rc" = 0 ] && bash "$SRC/ops/upgrade-check.sh" > "$OUT/check-tras-rollback.log" 2>&1; then
    ok "upgrade-check VERDE tras la vuelta atrás"; echo; echo "RESULTADO: VUELTA ATRÁS HECHA · el stack está como antes ($1)"; exit 2
  fi
  fail "upgrade-check tras la vuelta atrás: ver check-tras-rollback.log"
  echo; echo "RESULTADO: VUELTA ATRÁS FALLIDA · intervenir a mano con $OUT/imagenes-antes.txt"; exit 3
}
sec "4. Promoción (orden: indexer → manager → dashboard)"
T0=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for k in indexer manager dashboard; do
  case " $COMPONENTES " in *" $k "*) ;; *) continue;; esac
  PROMOTED+=("$k")
  [ "$MODE" = ensayo ] || docker tag "${CAND[$k]}" "${TAG[$k]}" || rollback "no pude etiquetar $k"
  info "$k: recreando con $(id_of "${TAG[$k]}")"
  up_svc "$k" || rollback "docker compose falló al recrear $k (compose.log)"
  wait_healthy "$k" && ok "$k sano" || rollback "$k no queda sano en 10 min"
done

# ------------------------------------------------------------------ 5. verificación en vivo
sec "5. Verificación en vivo"
case " $COMPONENTES " in *" manager "*|*" indexer "*)
  n=0
  for i in $(seq 1 40); do
    n=$(q 'triplesoc-alerts-*/_count' -H 'Content-Type: application/json' \
          -d "{\"query\":{\"range\":{\"timestamp\":{\"gte\":\"$T0\"}}}}" | grep -oE '"count":[0-9]+' | grep -oE '[0-9]+$')
    [ "${n:-0}" -gt 0 ] && break; sleep 15
  done
  [ "${n:-0}" -gt 0 ] && ok "llegan alertas nuevas al índice ($n desde $T0): manager → Filebeat → indexer funciona" \
    || rollback "no llega ninguna alerta nueva en 10 min"
esac
if bash "$SRC/ops/upgrade-check.sh" > "$OUT/check-despues.log" 2>&1; then ok "upgrade-check VERDE ($(grep -c '  OK ' "$OUT/check-despues.log") OK, $(grep -c '  WARN ' "$OUT/check-despues.log") avisos)"
else fail "upgrade-check ROJO:"; grep '  FAIL' "$OUT/check-despues.log" | sed 's/^/    /'; rollback "upgrade-check ROJO tras promocionar"; fi
[ "$MODE" = ensayo ] && rollback "simulacro: se fuerza la vuelta atrás para probarla"

{ echo "# Versión en uso (actualizado $(date -u '+%F %T') UTC por recibir-version)"
  for k in $COMPONENTES; do echo "$k wazuh=$V imagen=$(id_of "${TAG[$k]}") etiqueta=${TAG[$k]} copia=${BKP[$k]}"; done; } > /opt/triplesoc/releases/ACTUAL
cleanup_cands
echo; echo "RESULTADO: VERDE · Wazuh $V en producción. Volver atrás: re-etiquetar con imagenes-antes.txt + compose up --no-deps"
exit 0
