#!/usr/bin/env bash
# Objetos del indexer para la tubería triplesoc-alerts-* (idempotente, se puede re-ejecutar).
#   ./setup.sh               crea/actualiza template y política ISM
#   ./setup.sh migrate       además reindexa wazuh-alerts-4.x-* -> triplesoc-alerts-*
#   ./setup.sh purge-legacy  borra índices wazuh-alerts-4.x-* y el template legacy "wazuh"
#                            (solo si cada índice ya tiene su copia con el mismo nº de documentos)
# Se autentica con el certificado admin montado en el contenedor del indexer (sin contraseñas).
# Variables: INDEXER (contenedor), MANAGER (contenedor), RETENTION_DAYS (opcional: borra índices más viejos).
set -euo pipefail

INDEXER=${INDEXER:-wazuh-indexer-yf8u7icjiq4vdhetmea7rmfr}
MANAGER=${MANAGER:-wazuh-manager-yf8u7icjiq4vdhetmea7rmfr}
CERTS=/usr/share/wazuh-indexer/config/certs
RETENTION_DAYS=${RETENTION_DAYS:-}

api() { # api METHOD PATH [BODY_FILE]
  local body=()
  [[ -n "${3:-}" ]] && body=(-H 'Content-Type: application/json' --data-binary @-)
  docker exec -i "$INDEXER" curl -sk --fail-with-body --cert "$CERTS/admin.pem" --key "$CERTS/admin-key.pem" \
    -X "$1" "https://localhost:9200/$2" "${body[@]}" < "${3:-/dev/null}"
  echo
}
log() { echo "[triplesoc-indexer] $*"; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT

# 1. Template componible (visible en Index Management > Templates), derivado del template
#    oficial que trae el manager, así sigue las mappings de la versión instalada.
log "Template componible triplesoc-alerts"
docker exec "$MANAGER" cat /etc/filebeat/wazuh-template.json > "$WORK/legacy.json"
jq '{index_patterns: ["triplesoc-alerts-*", "triplesoc-archives-*"],
     priority: 100,
     version: (.version // 1),
     template: {settings: .settings, mappings: .mappings},
     _meta: {managed_by: "triplesoc-indexer/setup.sh"}}' "$WORK/legacy.json" > "$WORK/template.json"
api PUT _index_template/triplesoc-alerts "$WORK/template.json" >/dev/null

# 2. Política ISM de rotación para los índices diarios.
log "Política ISM triplesoc-alerts-rotation"
DELETE_STATE=''; WARM_TRANSITIONS='[]'
if [[ -n "$RETENTION_DAYS" ]]; then
  WARM_TRANSITIONS="[{\"state_name\":\"delete\",\"conditions\":{\"min_index_age\":\"${RETENTION_DAYS}d\"}}]"
  DELETE_STATE=',{"name":"delete","actions":[{"delete":{}}],"transitions":[]}'
fi
cat > "$WORK/policy.json" <<JSON
{"policy":{
  "description":"TripleSOC: rotación de índices diarios de alertas (hot 30 días -> warm solo lectura${RETENTION_DAYS:+ -> borrado a los ${RETENTION_DAYS} días})",
  "default_state":"hot",
  "states":[
    {"name":"hot","actions":[],"transitions":[{"state_name":"warm","conditions":{"min_index_age":"30d"}}]},
    {"name":"warm","actions":[{"read_only":{}}],"transitions":${WARM_TRANSITIONS}}${DELETE_STATE}
  ],
  "ism_template":[{"index_patterns":["triplesoc-alerts-*"],"priority":100}]
}}
JSON
EXISTING=$(api GET _plugins/_ism/policies/triplesoc-alerts-rotation 2>/dev/null || true)
if echo "$EXISTING" | jq -e '._seq_no' >/dev/null 2>&1; then
  SEQ=$(echo "$EXISTING" | jq -r '._seq_no'); TERM=$(echo "$EXISTING" | jq -r '._primary_term')
  api PUT "_plugins/_ism/policies/triplesoc-alerts-rotation?if_seq_no=$SEQ&if_primary_term=$TERM" "$WORK/policy.json" >/dev/null
else
  api PUT _plugins/_ism/policies/triplesoc-alerts-rotation "$WORK/policy.json" >/dev/null
fi
# Adjuntar la política a índices triplesoc existentes que no la tengan
# (los que ya la tienen aparecen como "failed" en la respuesta de ISM: es lo esperado).
echo '{"policy_id":"triplesoc-alerts-rotation"}' > "$WORK/add.json"
api POST '_plugins/_ism/add/triplesoc-alerts-*' "$WORK/add.json" | jq -r '"  índices con política recién adjuntada: \(.updated_indices)"' || true

case "${1:-}" in
  migrate)
    log "Reindexando wazuh-alerts-4.x-* -> triplesoc-alerts-*"
    cat > "$WORK/reindex.json" <<'JSON'
{"source":{"index":"wazuh-alerts-4.x-*"},
 "dest":{"index":"triplesoc-alerts-migrated","op_type":"create"},
 "script":{"lang":"painless","source":"ctx._index = ctx._index.replace('wazuh-alerts-4.x-', 'triplesoc-alerts-')"},
 "conflicts":"proceed"}
JSON
    api POST '_reindex?refresh=true&wait_for_completion=true' "$WORK/reindex.json" | jq -c '{total, created, version_conflicts, failures}'
    api POST '_plugins/_ism/add/triplesoc-alerts-*' "$WORK/add.json" >/dev/null || true
    ;;
  purge-legacy)
    log "Verificando copias antes de borrar"
    api GET '_cat/indices/wazuh-alerts-4.x-*?h=index,docs.count&format=json' > "$WORK/old.json"
    OK=1
    for row in $(jq -c '.[]' "$WORK/old.json"); do
      old=$(echo "$row" | jq -r .index); n=$(echo "$row" | jq -r '."docs.count"')
      new=${old/wazuh-alerts-4.x-/triplesoc-alerts-}
      m=$(api GET "_cat/count/$new?h=count" 2>/dev/null | tr -d '[:space:]' || echo 0)
      if [[ "$m" -ge "$n" ]]; then log "  $old ($n) -> $new ($m) OK"; else log "  $old ($n) -> $new ($m) FALTA"; OK=0; fi
    done
    [[ $OK == 1 ]] || { log "ERROR: hay índices sin copia completa; no se borra nada"; exit 1; }
    for old in $(jq -r '.[].index' "$WORK/old.json"); do api DELETE "$old" >/dev/null; log "  borrado $old"; done
    api DELETE _template/wazuh >/dev/null 2>&1 && log "  borrado template legacy wazuh" || true
    ;;
esac

log "Estado:"
api GET '_cat/indices/triplesoc-alerts-*,wazuh-alerts-*?v&h=index,docs.count,store.size&s=index'
api GET '_cat/templates/triplesoc*?v&h=name,index_patterns'
api GET '_cat/templates/wazuh?h=name,index_patterns'
api GET '_plugins/_ism/explain/triplesoc-alerts-*' | jq -r 'to_entries[] | select(.value|type=="object") | "  \(.key): \(.value["index.plugins.index_state_management.policy_id"] // .value.policy_id // "sin política")"'
