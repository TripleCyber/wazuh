#!/bin/bash
# Comprobación de que todo lo propio de TripleSOC sigue funcionando.
# Se ejecuta después de cualquier actualización (de Wazuh o nuestra) y SOLO LEE: no cambia nada.
#   ./upgrade-check.sh            → stack de Coolify (servicio yf8u7icjiq4vdhetmea7rmfr)
#   SID=<otro> ./upgrade-check.sh → otro stack (por ejemplo, el canario)
# Salida: una línea OK/WARN/FAIL por comprobación. Código 0 = verde, 1 = rojo (hay algún FAIL).
SID=${SID:-yf8u7icjiq4vdhetmea7rmfr}
SVC_DIR=${SVC_DIR:-/data/coolify/services/$SID}
MAX_ALERT_AGE_MIN=${MAX_ALERT_AGE_MIN:-60}

MGR=wazuh-manager-$SID
IDX=wazuh-indexer-$SID
DSH=wazuh-dashboard-$SID
FAILS=0; WARNS=0
ok()   { printf '  OK    %s\n' "$*"; }
warn() { printf '  WARN  %s\n' "$*"; WARNS=$((WARNS+1)); }
fail() { printf '  FAIL  %s\n' "$*"; FAILS=$((FAILS+1)); }
sec()  { printf '\n[%s]\n' "$*"; }
mx()   { docker exec "$MGR" "$@" 2>&1; }
int()  { local v; v=$(printf '%s' "$1" | tr -d '\r' | grep -oE '^[0-9]+$' | head -1); echo "${v:-0}"; }
q()    { docker exec "$IDX" curl -sk --max-time 15 \
           --cert /usr/share/wazuh-indexer/config/certs/admin.pem \
           --key /usr/share/wazuh-indexer/config/certs/admin-key.pem \
           "https://localhost:9200/$1" "${@:2}" 2>/dev/null; }

echo "TripleSOC upgrade-check · $(date -u '+%F %T') UTC · stack $SID"

# ------------------------------------------------------------------ 1. imágenes
# La limpieza nocturna de Coolify ya borró etiquetas en uso (01-10 y 16-10): con
# pull_policy never, un reinicio fallaría. Cada imagen del compose debe existir con su etiqueta.
sec "Imágenes del compose"
if [ -f "$SVC_DIR/docker-compose.yml" ]; then
  for img in $(grep -E '^\s+image:' "$SVC_DIR/docker-compose.yml" | sed -E "s/.*image: *['\"]?([^'\"]+)['\"]?/\1/"); do
    if docker image inspect "$img" >/dev/null 2>&1; then
      lbl=$(docker image inspect -f '{{index .Config.Labels "coolify.managed"}}' "$img" 2>/dev/null)
      case "$img" in
        triplesoc/*) [ "$lbl" = "true" ] && ok "$img" || fail "$img sin LABEL coolify.managed=true (la limpieza nocturna la borrará)";;
        *)           ok "$img";;
      esac
    else
      fail "$img no existe en el servidor (un reinicio fallaría)"
    fi
  done
else
  fail "no existe $SVC_DIR/docker-compose.yml"
fi

# ------------------------------------------------------------------ 2. contenedores
sec "Contenedores"
for c in wazuh-indexer wazuh-manager wazuh-dashboard triplesoc-webhook-receiver triplesoc-incidents triplesoc-responder triplesoc-rulesmith; do
  st=$(docker inspect -f '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{end}}' "$c-$SID" 2>/dev/null)
  case "$st" in
    "running healthy") ok "$c";;
    running*)          warn "$c: $st";;
    *)                 fail "$c: ${st:-no existe}";;
  esac
done

# ------------------------------------------------------------------ 3. manager y reglas
sec "Manager: reglas, decoders e integraciones"
v=$(mx cat /var/ossec/etc/ossec-init.conf 2>/dev/null | grep -o 'VERSION="[^"]*"' || mx /var/ossec/bin/wazuh-control info -v)
ok "versión: $(echo "$v" | tr -d '\r' | head -1)"
t=$(mx /var/ossec/bin/wazuh-analysisd -t)
if [ $? -eq 0 ] && ! echo "$t" | grep -qiE 'error|critical'; then ok "wazuh-analysisd -t sin errores"; else fail "wazuh-analysisd -t: $(echo "$t" | grep -iE 'error|critical' | head -3)"; fi
for f in /var/ossec/etc/rules/triplesoc_rules.xml /var/ossec/etc/decoders/triplesoc_decoders.xml; do
  a=$(mx md5sum "$f" | cut -d' ' -f1); b=$(mx md5sum "/opt/triplesoc/${f#/var/ossec/etc/}" | cut -d' ' -f1)
  [ -n "$a" ] && [ "$a" = "$b" ] && ok "$(basename "$f") instalado (igual que la imagen)" || fail "$(basename "$f") ausente o distinto de la imagen"
done
n=$(int "$(mx grep -c '<rule id="1009' /var/ossec/etc/rules/triplesoc_rules.xml)")
[ "$n" -ge 22 ] && ok "$n reglas propias 1009xx" || fail "solo $n reglas propias 1009xx (esperadas ≥ 22)"
for r in 100911 100928 100929 100940 100943; do
  mx grep -q "rule id=\"$r\"" /var/ossec/etc/rules/triplesoc_rules.xml && ok "regla $r presente" || fail "regla $r no encontrada"
done
for f in custom-triplesoc custom-triplesoc.py; do
  mx test -x "/var/ossec/integrations/$f" && ok "integración $f" || fail "integración $f ausente o no ejecutable"
done
c=$(int "$(mx grep -c '<name>custom-triplesoc</name>' /var/ossec/etc/ossec.conf)")
[ "${c:-0}" -ge 2 ] && ok "ossec.conf: $c bloques <integration> custom-triplesoc (receptor + Teams)" || fail "ossec.conf: ${c:-0} bloques custom-triplesoc (esperados 2)"
mx test -s /var/ossec/etc/triplesoc-teams.url && ok "URL de Teams configurada (no se muestra)" || fail "falta /var/ossec/etc/triplesoc-teams.url"
d1=$(date -u +%Y/%m/%d); d2=$(date -u -d yesterday +%Y/%m/%d)
e=$(int "$(mx sh -c "tail -n 2000 /var/ossec/logs/integrations.log 2>/dev/null | grep -E '^($d1|$d2)' | grep -ciE 'error|traceback'")")
[ "${e:-0}" -eq 0 ] && ok "integrations.log sin errores en 24 h" || warn "integrations.log: $e líneas con error en 24 h (envíos a Teams o al receptor)"

# ------------------------------------------------------------------ 4. tubería de datos
# ------------------------------------------------------------------ 4a. disco y bloqueos del indexer
# Lección del 20-10: al pasar del 90 % de disco, OpenSearch puso cluster.blocks.create_index=true y no lo
# quitó al bajar. Con el bloqueo puesto, el índice diario de alertas de las 00:00 UTC no se podría crear.
sec "Disco y bloqueos del indexer"
pct=$(int "$(q '_cat/allocation?h=disk.percent' | tr -d ' ' | head -1)")
if   [ "$pct" -ge 85 ]; then fail "disco del indexer al ${pct} % (al 90 % bloquea índices nuevos y al 95 % pasa a solo lectura)"
elif [ "$pct" -ge 80 ]; then warn "disco del indexer al ${pct} % (ampliar antes de actualizar versiones)"
else ok "disco del indexer al ${pct} %"; fi
blk=$(q '_cluster/state/blocks?filter_path=blocks.global' | grep -o '"description":"[^"]*"' | cut -d'"' -f4 | tr '\n' ';')
[ -z "$blk" ] && ok "sin bloqueos globales en el clúster" || fail "bloqueos en el clúster: $blk (revisar disco y quitar con _cluster/settings)"
# La política triplesoc-alerts-rotation pasa a solo lectura (estado warm) los índices de alertas de más de 30 días:
# ese bloqueo de escritura es el previsto. Falla si lo tiene el índice de hoy o cualquier otro índice.
wb=$(q '_all/_settings/index.blocks.write?flat_settings=true' | grep -oE '"[^"]+":\{"settings":\{"index.blocks.write":"true"' | cut -d'"' -f2)
today="triplesoc-alerts-$(date -u +%Y.%m.%d)"
other=$(printf '%s\n' $wb | grep -vE '^triplesoc-alerts-[0-9]{4}\.[0-9]{2}\.[0-9]{2}$' | tr '\n' ' ')
if printf '%s\n' $wb | grep -qx "$today"; then fail "el índice de hoy ($today) no admite escrituras"
elif [ -n "$other" ]; then fail "índices con escritura bloqueada: $other"
else ok "índices aceptan escrituras ($(printf '%s\n' $wb | grep -c .) de alertas antiguos en solo lectura por la retención de 30 días)"; fi
ro=$(q '_all/_settings/index.blocks.read_only_allow_delete?flat_settings=true' | grep -c '"true"')
[ "${ro:-0}" -eq 0 ] && ok "ningún índice en solo lectura" || fail "$ro índices en solo lectura por disco"

sec "Tubería de alertas (Filebeat → triplesoc-alerts-*)"
mx grep -q 'default: triplesoc-alerts-' /usr/share/filebeat/module/wazuh/alerts/manifest.yml \
  && ok "Filebeat escribe en triplesoc-alerts-*" || fail "el prefijo de Filebeat ya no es triplesoc-alerts- (las alertas irían a wazuh-alerts-*)"
hj=$(q "_cluster/health")
h=$(echo "$hj" | grep -o '"status":"[a-z]*"' | cut -d'"' -f4)
nodes=$(echo "$hj" | grep -o '"number_of_nodes":[0-9]*' | cut -d: -f2)
case "$h" in
  green)  ok "indexer: green";;
  yellow) [ "$nodes" = "1" ] && ok "indexer: yellow (normal con un solo nodo: réplicas sin asignar)" || warn "indexer: yellow con $nodes nodos";;
  *)      fail "indexer: ${h:-sin respuesta}";;
esac
last=$(q "triplesoc-alerts-*/_search?size=1&sort=timestamp:desc&_source=timestamp" | grep -o '"timestamp":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$last" ]; then
  fail "no hay alertas en triplesoc-alerts-*"
else
  age=$(( ( $(date -u +%s) - $(date -u -d "${last%%.*}" +%s 2>/dev/null || echo 0) ) / 60 ))
  [ "$age" -le "$MAX_ALERT_AGE_MIN" ] && ok "última alerta hace $age min ($last)" || warn "última alerta hace $age min (más de $MAX_ALERT_AGE_MIN): ¿llegan alertas?"
fi
w=$(q "_cat/indices/wazuh-alerts-*$(date -u +%Y.%m.%d)?h=index")
[ -z "$w" ] && ok "no se crean índices wazuh-alerts-* de hoy" || fail "hay índices nuevos con el nombre original: $w"

# ------------------------------------------------------------------ 5. agentes y scripts del endpoint
sec "Agentes y grupo triplesoc-endpoints"
act=$(int "$(mx /var/ossec/bin/agent_control -l | grep -v 'ID: 000' | grep -c 'Active')")
[ "${act:-0}" -ge 1 ] && ok "$act agente(s) activo(s)" || warn "ningún agente activo ahora mismo"
G=/var/ossec/etc/shared/triplesoc-endpoints
for f in agent.conf triplesoc-usb-audit.ps1; do
  a=$(mx md5sum "$G/$f" | cut -d' ' -f1); b=$(mx md5sum "/opt/triplesoc/endpoints/triplesoc-endpoints/$f" | cut -d' ' -f1)
  [ -n "$a" ] && [ "$a" = "$b" ] && ok "$f del grupo igual que la imagen" || fail "$f del grupo ausente o distinto"
done
mx test -f "$G/triplesoc-usb-allowlist.txt" && ok "lista de USB permitidos presente" || fail "falta triplesoc-usb-allowlist.txt"
mx /var/ossec/bin/agent_groups -l -g triplesoc-endpoints 2>/dev/null | grep -qE '^ *[0-9]' \
  && ok "hay agentes en el grupo triplesoc-endpoints" || warn "el grupo triplesoc-endpoints no tiene agentes"

# ------------------------------------------------------------------ 6. dashboard y marca
sec "Dashboard y marca TripleSOC"
code=$(docker exec "$DSH" curl -sk -o /dev/null -w '%{http_code}' --max-time 15 http://localhost:5601/app/login 2>/dev/null)
[ "$code" = "200" ] && ok "dashboard responde (HTTP 200)" || fail "dashboard responde HTTP ${code:-nada}"
J=/usr/share/wazuh-dashboard/src/core/target/public/core.entry.js
for m in schema nav incidents rules guardian assistant login; do
  n=$(docker exec "$DSH" grep -c "==== TripleSOC $m ====" "$J" 2>/dev/null)
  [ "${n:-0}" -eq 1 ] && ok "módulo TripleSOC $m en el bundle" || fail "módulo TripleSOC $m: ${n:-0} copias (esperada 1)"
done
docker exec "$DSH" grep -q 'TripleSOC visual layer' /usr/share/wazuh-dashboard/src/core/server/core_app/assets/wz_v7_theme_overwrite.css 2>/dev/null \
  && ok "capa visual (CSS) aplicada" || fail "capa visual (CSS) no aplicada"
docker exec "$DSH" grep -q 'triplesoc-alerts-' /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml 2>/dev/null \
  && ok "wazuh.yml apunta a triplesoc-alerts-*" || fail "wazuh.yml no apunta a triplesoc-alerts-*"

# ------------------------------------------------------------------ 7. servicios propios
sec "Servicios TripleSOC (Responder, Incidents, Rulesmith, receptor)"
for c in triplesoc-responder triplesoc-incidents triplesoc-rulesmith; do
  tb=$(docker logs --since 30m "$c-$SID" 2>&1 | grep -c 'Traceback')
  [ "${tb:-0}" -eq 0 ] && ok "$c sin errores en 30 min" || fail "$c: $tb Traceback en 30 min"
done
# Las imágenes de los servicios no llevan shell (solo Python): las comprobaciones dentro se hacen con python -c.
docker exec "triplesoc-responder-$SID" python -c "import sys; sys.exit('def prompt_injection' not in open('/app/responder.py').read())" 2>/dev/null \
  && ok "Responder con guardarraíles de IA (inyección + techo de severidad)" || fail "Responder sin guardarraíles de IA"
docker exec "triplesoc-webhook-receiver-$SID" python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/', timeout=4)" >/dev/null 2>&1 \
  && ok "receptor de webhooks responde" || fail "receptor de webhooks no responde"

# ------------------------------------------------------------------ 7b. capa traductora (fase 2)
# Todos los consumidores leen índice y campos del mismo contrato (schema/triplesoc-schema.json).
sec "Capa traductora (contrato de esquema)"
SCHEMA_SRC=${SCHEMA_SRC:-$(cd "$(dirname "$0")/.." && pwd)/schema/triplesoc-schema.json}
if [ -f "$SCHEMA_SRC" ]; then
  want=$(md5sum < "$SCHEMA_SRC" | cut -c1-32)
  for c in triplesoc-responder triplesoc-incidents triplesoc-rulesmith; do
    got=$(docker exec "$c-$SID" python -c 'import hashlib; print(hashlib.md5(open("/app/triplesoc-schema.json", "rb").read()).hexdigest())' 2>/dev/null | cut -c1-32)
    imp=$(docker exec "$c-$SID" python -c 'import sys; sys.path.insert(0, "/app"); import tsoc_schema as T; print(T.ADAPTER)' 2>/dev/null | tr -d '\r')
    if [ "$got" = "$want" ] && [ -n "$imp" ]; then ok "$c usa el contrato del repositorio (adaptador $imp)"
    elif [ -z "$got" ]; then fail "$c no tiene la capa traductora (/app/triplesoc-schema.json)"
    else fail "$c tiene otro contrato (md5 ${got:0:8} ≠ ${want:0:8}) o no carga tsoc_schema"; fi
  done
  ct=$(grep -o '"contract": *"[^"]*"' "$SCHEMA_SRC" | cut -d'"' -f4)
  docker exec "$DSH" grep -q "\"contract\": *\"$ct\"" "$J" 2>/dev/null \
    && ok "dashboard con el contrato $ct incrustado" || fail "el bundle del dashboard no lleva el contrato $ct"
else
  warn "no encuentro $SCHEMA_SRC (ejecutar desde /opt/triplesoc/src/ops o pasar SCHEMA_SRC=)"
fi

# ------------------------------------------------------------------ resultado
echo
if [ "$FAILS" -eq 0 ]; then
  echo "RESULTADO: VERDE ($WARNS avisos)"; exit 0
else
  echo "RESULTADO: ROJO ($FAILS fallos, $WARNS avisos)"; exit 1
fi
