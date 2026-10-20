#!/bin/bash
# Fase 3 · canario ligero. Valida imágenes CANDIDATAS sin tocar el stack: contenedores desechables,
# sin red y con límite de memoria. No necesita un segundo indexer (no cabe en la RAM del servidor).
#   ./canary.sh                      → las imágenes del compose actual (línea base)
#   MGR=triplesoc/wazuh-manager:4.14.8 DSH=triplesoc/wazuh-dashboard:4.14.8 ./canary.sh   → candidatas
# Comprueba: 1) motor (analysisd -t + logtest de canary/logtest-cases.txt: nuestras reglas siguen saltando),
# 2) dashboard (capa traductora, 6 módulos, sintaxis del bundle), 3) servicios (set de oro de la capa,
# guardarraíles de IA) y 4) el set de oro de decisiones: recall de contención 100 % y 0 benignas escaladas.
# Salida VERDE (exit 0) / ROJO (exit 1). Informe en /opt/triplesoc/canary/<fecha-hora>/.
SID=${SID:-yf8u7icjiq4vdhetmea7rmfr}
SRC=$(cd "$(dirname "$0")/.." && pwd)
CMP=/data/coolify/services/$SID/docker-compose.yml
img() { grep -oE "image: '[^']*$1:[^']*'" "$CMP" | head -1 | cut -d"'" -f2; }
MGR=${MGR:-$(img wazuh-manager)}; DSH=${DSH:-$(img wazuh-dashboard)}
RSP=${RSP:-$(img responder)}; INC=${INC:-$(img incidents)}; RUL=${RUL:-$(img rulesmith)}
GOLDEN=${GOLDEN:-$(ls -d /opt/triplesoc/golden/2* 2>/dev/null | tail -1)}
OUT=/opt/triplesoc/canary/$(date -u +%Y%m%d-%H%M); mkdir -p "$OUT"; chmod 700 /opt/triplesoc/canary
FAILS=0
ok()   { printf '  OK    %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; FAILS=$((FAILS+1)); }
sec()  { printf '\n[%s]\n' "$*"; }
C=tsoc-canary-mgr-$$
trap 'docker rm -f $C >/dev/null 2>&1' EXIT
{
echo "TripleSOC canario · $(date -u '+%F %T') UTC"
echo "  manager=$MGR dashboard=$DSH responder=$RSP incidents=$INC rulesmith=$RUL"

sec "1. Motor ($MGR)"
docker run -d --name $C --network none --memory 1500m "$MGR" >/dev/null || fail "no arranca $MGR"
for i in $(seq 1 40); do docker exec $C /var/ossec/bin/wazuh-control status 2>/dev/null | grep -q 'wazuh-analysisd is running' && break; sleep 3; done
docker exec $C /var/ossec/bin/wazuh-analysisd -t >/dev/null 2>&1 && ok "analysisd -t (configuración, reglas y decoders)" || fail "analysisd -t falla"
for f in rules/triplesoc_rules.xml decoders/triplesoc_decoders.xml; do
  a=$(docker exec $C md5sum /var/ossec/etc/$f 2>/dev/null | cut -c1-32); b=$(md5sum < "$SRC/triplesoc-manager/$f" | cut -c1-32)
  [ "$a" = "$b" ] && ok "$f igual que el repositorio" || fail "$f distinto del repositorio"
done
while IFS='|' read -r want log; do
  case "$want" in ''|\#*) continue;; esac
  got=$(printf '%s\n' "$log" | docker exec -i $C /var/ossec/bin/wazuh-logtest 2>&1 | grep -oE "id: '[0-9]+'" | tail -1 | grep -oE '[0-9]+')
  if [ "$want" = BASE ]; then
    [ -n "$got" ] && [ "${got#1009}" = "$got" ] && ok "log normal → regla $got (no salta una nuestra)" || fail "log normal → '${got:-nada}'"
  else
    [ "$got" = "$want" ] && ok "regla $want salta" || fail "esperada $want, salta '${got:-nada}': ${log:0:60}"
  fi
done < "$SRC/ops/canary/logtest-cases.txt"

sec "2. Dashboard ($DSH)"
docker run --rm --network none -v "$SRC":/src:ro --entrypoint /usr/share/wazuh-dashboard/node/bin/node "$DSH" /src/ops/schema-test.js \
  | grep -q 'RESULTADO: VERDE' && ok "capa traductora (set de oro JS)" || fail "capa traductora del dashboard"
n=$(docker run --rm --network none --entrypoint sh "$DSH" -c 'grep -o "==== TripleSOC [a-z]* ====" /usr/share/wazuh-dashboard/src/core/target/public/core.entry.js | wc -l')
[ "$n" = 6 ] && ok "6 módulos TripleSOC en el bundle" || fail "módulos en el bundle: $n (esperados 6)"
docker run --rm --network none --entrypoint sh "$DSH" -c '/usr/share/wazuh-dashboard/node/bin/node --check /usr/share/wazuh-dashboard/src/core/target/public/core.entry.js' \
  && ok "sintaxis del bundle" || fail "el bundle tiene errores de sintaxis"

sec "3. Servicios"
for p in "$RSP responder" "$INC incidents" "$RUL rulesmith"; do set -- $p
  docker run --rm --network none -v "$SRC/ops":/t:ro "$1" python /t/schema-test.py "$2" | grep -q 'RESULTADO: VERDE' \
    && ok "$2: capa traductora" || fail "$2: capa traductora"
done
docker run --rm --network none -v "$SRC/ops":/t:ro "$RSP" python /t/ai-guard-test.py | grep -q 'TODO PASA' \
  && ok "responder: guardarraíles de IA (10 casos)" || fail "responder: guardarraíles de IA"

sec "4. Set de oro de decisiones"
if [ -f "$GOLDEN/sample.jsonl" ]; then
  mkdir -p "$OUT/golden" && cp "$GOLDEN/sample.jsonl" "$OUT/golden/"
  s=$(docker run --rm -u 0 --network none -v "$SRC":/src:ro -v "$OUT/golden":/g "$RSP" python /src/ops/golden/eval-golden.py /g | tail -1)
  rec=$(echo "$s" | grep -oE '"containment_recall": [0-9.]+' | grep -oE '[0-9.]+$'); esc=$(echo "$s" | grep -oE '"benign_escalated": [0-9]+' | grep -oE '[0-9]+$')
  acc=$(echo "$s" | grep -oE '"accuracy": [0-9.]+' | grep -oE '[0-9.]+$')
  [ "$rec" = "1.0" ] && ok "recall de contención 100 %" || fail "recall de contención ${rec:-?}"
  [ "$esc" = "0" ] && ok "0 benignas escaladas a contención" || fail "benignas escaladas: ${esc:-?}"
  echo "  INFO  acierto global ${acc:-?} (muestra $GOLDEN)"
else
  fail "no hay muestra del set de oro en /opt/triplesoc/golden (ver ops/golden/README.md)"
fi

echo
[ "$FAILS" -eq 0 ] && echo "RESULTADO: VERDE" || echo "RESULTADO: ROJO ($FAILS fallos)"
} 2>&1 | tee "$OUT/canario.log"
grep -q 'RESULTADO: VERDE' "$OUT/canario.log"
