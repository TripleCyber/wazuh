#!/bin/bash
# Roles de Logto -> roles de la API de Wazuh (run_as). Idempotente.
# El dashboard llama a la API de Wazuh como wazuh-wui con run_as: la API decide los permisos con estas reglas,
# a partir del contexto del usuario (backend_roles = claim "roles" de Logto). Sin regla, sin permisos.
#   tsoc-admin -> administrator    tsoc-analista / tsoc-lectura -> readonly    sin rol -> nada
# - Respalda reglas y roles actuales. No toca las reglas por defecto (admin local sigue siendo administrator).
# - Comprueba con run_as simulado: admin, analista, lectura, sin rol y el admin local.
# Volver atrás: DELETE /security/rules?rule_ids=<ids de tsoc_*> (los ids salen en el respaldo y en el log).
set -euo pipefail
S=${SID:-yf8u7icjiq4vdhetmea7rmfr}; M=wazuh-manager-$S; D=wazuh-dashboard-$S
B=${BACKUP:-/opt/triplesoc/backup-$(date +%Y%m%d-%H%M%S)-rbac}
mkdir -p "$B"; chmod 700 "$B"

P=$(docker exec "$D" printenv API_PASSWORD)
TK=$(docker exec "$M" curl -sk -u "wazuh-wui:$P" -X POST 'https://localhost:55000/security/user/authenticate?raw=true')
[ -n "$TK" ] && [ "${TK#\{}" = "$TK" ] || { echo "no se pudo autenticar en la API de Wazuh"; exit 1; }
api() { docker exec -i "$M" curl -sk -X "$1" -H "Authorization: Bearer $TK" -H 'Content-Type: application/json' \
  ${3:+--data-binary @-} "https://localhost:55000$2" <<< "${3:-}"; }

api GET '/security/rules?limit=500' > "$B/rules.json"
api GET '/security/roles?limit=500' > "$B/roles.json"
chmod 600 "$B"/*.json
echo "respaldo: $B"

# nombre de regla | backend role de Logto | nombre del rol de Wazuh
while IFS='|' read -r NAME BR ROLE; do
  RID=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(next(r["id"] for r in d["data"]["affected_items"] if r["name"]==sys.argv[2]))' "$B/roles.json" "$ROLE")
  RULE=$(api GET '/security/rules?limit=500' | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((r["id"] for r in d["data"]["affected_items"] if r["name"]==sys.argv[1]), ""))' "$NAME")
  if [ -z "$RULE" ]; then
    RULE=$(api POST /security/rules "{\"name\": \"$NAME\", \"rule\": {\"FIND\": {\"backend_roles\": [\"$BR\"]}}}" \
      | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["data"]["affected_items"][0]["id"]) if d.get("error")==0 else sys.exit("error: %s" % d)')
    echo "regla $NAME creada (id $RULE): backend_roles contiene $BR"
  else
    echo "regla $NAME ya estaba (id $RULE)"
  fi
  api POST "/security/roles/$RID/rules?rule_ids=$RULE" > /dev/null
  echo "  -> rol $ROLE (id $RID)"
done <<'MAP'
tsoc_admin|tsoc-admin|administrator
tsoc_analista|tsoc-analista|readonly
tsoc_lectura|tsoc-lectura|readonly
MAP

# Comprobación: contexto como el que envía el dashboard (authinfo del plugin de seguridad).
check() {
  local T; T=$(docker exec "$M" curl -sk -u "wazuh-wui:$P" -X POST -H 'Content-Type: application/json' -d "$2" \
    'https://localhost:55000/security/user/authenticate/run_as?raw=true')
  docker exec "$M" curl -sk -H "Authorization: Bearer $T" 'https://localhost:55000/security/users/me' \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); r=sorted(x["name"] for u in d["data"]["affected_items"] for x in u["roles"]); print("  %-12s -> %s" % (sys.argv[1], ", ".join(r) or "SIN PERMISOS"))' "$1"
}
# Wazuh revoca los tokens emitidos hasta el segundo del último cambio de seguridad: esperar antes de comprobar.
sleep 2
echo "comprobación (run_as):"
check "tsoc-admin"    '{"user_name":"prueba-admin","backend_roles":["tsoc-admin"],"roles":["all_access","own_index"]}'
check "tsoc-analista" '{"user_name":"prueba-analista","backend_roles":["tsoc-analista"],"roles":["readall","own_index"]}'
check "tsoc-lectura"  '{"user_name":"prueba-lectura","backend_roles":["tsoc-lectura"],"roles":["readall","own_index"]}'
check "sin rol"       '{"user_name":"prueba-sinrol","backend_roles":[],"roles":["own_index"]}'
check "admin local"   '{"user_name":"admin","backend_roles":["admin"],"roles":["all_access","own_index"]}'
unset P TK
echo "wazuh-rbac: HECHO"
