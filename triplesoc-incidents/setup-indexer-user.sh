#!/usr/bin/env bash
# Crea (o actualiza) el usuario del indexer que usa el servicio, con permisos mínimos:
#   - lectura de triplesoc-alerts-*
#   - escritura solo en triplesoc-incidents*
# La contraseña se genera aquí y se guarda en $SECRET_DIR/indexer_password (0640, uid 10001);
# nunca se imprime.  Uso:  ./setup-indexer-user.sh <contenedor-indexer>
set -euo pipefail
IDX=${1:?contenedor del indexer}
SECRET_DIR=${SECRET_DIR:-/opt/triplesoc/triplesoc-incidents/secret}
CERTS=/usr/share/wazuh-indexer/config/certs
api() { docker exec -i "$IDX" curl -sk --cert $CERTS/admin.pem --key $CERTS/admin-key.pem \
          -H 'Content-Type: application/json' -X "$1" "https://localhost:9200/_plugins/_security/api/$2" -d @-; echo; }

mkdir -p "$SECRET_DIR"
if [[ ! -s "$SECRET_DIR/indexer_password" ]]; then
  (umask 077; openssl rand -hex 24 > "$SECRET_DIR/indexer_password")
fi
chown 10001 "$SECRET_DIR/indexer_password"; chmod 0400 "$SECRET_DIR/indexer_password"

api PUT roles/triplesoc_incidents_svc <<'JSON'
{"description": "TripleSOC Incidents: lee alertas, escribe solo sus índices",
 "cluster_permissions": ["cluster_composite_ops"],
 "index_permissions": [
   {"index_patterns": ["triplesoc-alerts-*"], "allowed_actions": ["read"]},
   {"index_patterns": ["triplesoc-incidents*"], "allowed_actions": ["crud", "create_index", "indices:admin/mapping/put", "indices:admin/refresh*"]}
 ]}
JSON
printf '{"password":"%s","description":"TripleSOC Incidents (servicio de correlacion)"}' "$(cat "$SECRET_DIR/indexer_password")" \
  | api PUT internalusers/triplesoc_incidents
echo '{"users":["triplesoc_incidents"]}' | api PUT rolesmapping/triplesoc_incidents_svc
