#!/usr/bin/env bash
# Crea (o actualiza) el usuario de la API de Wazuh que usa el servicio para EJECUTAR respuestas,
# con permisos mínimos: lanzar active response y leer el estado de los agentes. Nada más.
# La contraseña se genera aquí y se guarda en $SECRET_DIR/wazuh_api_password (0400, uid 10001);
# nunca se imprime. Las credenciales de administrador se leen del entorno del propio manager.
#   Uso:  ./setup-api-user.sh <contenedor-manager>
set -euo pipefail
MGR=${1:?contenedor del manager}
SECRET_DIR=${SECRET_DIR:-/opt/triplesoc/responder-secrets}
USER_NAME=triplesoc_responder
ROLE_NAME=triplesoc_responder_svc
POLICY_NAME=triplesoc_responder_ar

mkdir -p "$SECRET_DIR"
chown 10001 "$SECRET_DIR"; chmod 0700 "$SECRET_DIR"
if [[ ! -s "$SECRET_DIR/wazuh_api_password" ]]; then
  # La API exige mayúscula, minúscula, número y símbolo.
  (umask 077; printf 'Ts1!%s' "$(openssl rand -hex 20)" > "$SECRET_DIR/wazuh_api_password")
fi
chown 10001 "$SECRET_DIR/wazuh_api_password"; chmod 0400 "$SECRET_DIR/wazuh_api_password"

# Token de administrador (usuario y contraseña del entorno del manager; no salen del contenedor).
TOKEN=$(docker exec "$MGR" sh -c 'curl -sk -u "${API_USERNAME:-wazuh-wui}:$API_PASSWORD" -X POST https://localhost:55000/security/user/authenticate?raw=true')
[[ "$TOKEN" == ey* ]] || { echo "ERROR: no se pudo autenticar como administrador de la API"; exit 1; }

api() {  # api METHOD PATH [JSON]   -> respuesta JSON
  local body=${3:-}
  if [[ -n "$body" ]]; then
    printf '%s' "$body" | docker exec -i "$MGR" curl -sk -H "Authorization: Bearer $TOKEN" \
      -H 'Content-Type: application/json' -X "$1" "https://localhost:55000$2" -d @-
  else
    docker exec "$MGR" curl -sk -H "Authorization: Bearer $TOKEN" -X "$1" "https://localhost:55000$2"
  fi
}
id_of() {  # id_of PATH CAMPO VALOR   -> id del elemento cuyo CAMPO es exactamente VALOR (vacío si no existe)
  api GET "$1?limit=500" | python3 -c "
import json, sys
items = json.load(sys.stdin).get('data', {}).get('affected_items', [])
print(next((str(i['id']) for i in items if i.get('$2') == '$3'), ''))"
}

POLICY_ID=$(id_of /security/policies name "$POLICY_NAME")
if [[ -z "$POLICY_ID" ]]; then
  api POST /security/policies "{\"name\":\"$POLICY_NAME\",\"policy\":{\"actions\":[\"active-response:command\",\"agent:read\"],\"resources\":[\"agent:id:*\"],\"effect\":\"allow\"}}" > /dev/null
  POLICY_ID=$(id_of /security/policies name "$POLICY_NAME")
fi
ROLE_ID=$(id_of /security/roles name "$ROLE_NAME")
if [[ -z "$ROLE_ID" ]]; then
  api POST /security/roles "{\"name\":\"$ROLE_NAME\"}" > /dev/null
  ROLE_ID=$(id_of /security/roles name "$ROLE_NAME")
fi
[[ -n "$POLICY_ID" && -n "$ROLE_ID" ]] || { echo "ERROR: no se pudo crear la política o el rol"; exit 1; }
api POST "/security/roles/$ROLE_ID/policies?policy_ids=$POLICY_ID" > /dev/null

PASS_JSON=$(python3 -c "import json,sys; print(json.dumps(open(sys.argv[1]).read().strip()))" "$SECRET_DIR/wazuh_api_password")
USER_ID=$(id_of /security/users username "$USER_NAME")
if [[ -z "$USER_ID" ]]; then
  api POST /security/users "{\"username\":\"$USER_NAME\",\"password\":$PASS_JSON}" > /dev/null
  USER_ID=$(id_of /security/users username "$USER_NAME")
else
  api PUT "/security/users/$USER_ID" "{\"password\":$PASS_JSON}" > /dev/null
fi
[[ -n "$USER_ID" ]] || { echo "ERROR: no se pudo crear el usuario"; exit 1; }
api POST "/security/users/$USER_ID/roles?role_ids=$ROLE_ID" > /dev/null

# Comprobación: el usuario nuevo puede autenticarse.
CHECK=$(printf '%s' "$(cat "$SECRET_DIR/wazuh_api_password")" | docker exec -i "$MGR" sh -c \
  'curl -sk -u "'"$USER_NAME"':$(cat)" -X POST https://localhost:55000/security/user/authenticate?raw=true')
[[ "$CHECK" == ey* ]] && echo "OK: usuario $USER_NAME listo (política $POLICY_ID, rol $ROLE_ID, usuario $USER_ID)" \
  || { echo "ERROR: el usuario se creó pero no puede autenticarse"; exit 1; }
