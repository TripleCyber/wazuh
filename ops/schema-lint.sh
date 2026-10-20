#!/bin/bash
# Fase 2 · vigilante de la capa traductora. Falla (exit 1) si algún consumidor vuelve a escribir
# a mano el índice de alertas o un campo de Wazuh en vez de pedírselo a la capa:
#   Python  → schema/tsoc_schema.py      (TS.ALERTS_INDEX, TS.F[...], TS.sev_gte(...))
#   Dashboard → overlay/triplesoc-schema.js (TS.idx.alerts, TS.f..., TS.kql..., TS.sevGte(...))
# Solo mira literales entre comillas (los comentarios pueden nombrar los campos).
# Lado productor, fuera de la regla a propósito (es Wazuh 4.x y cambia con su adaptador):
#   triplesoc-manager (prefijo de Filebeat y reglas XML), triplesoc-indexer (template e ISM),
#   setup-indexer-user.sh (rol) y ops/upgrade-check.sh (comprueba justo esos nombres).
#   ./schema-lint.sh        desde cualquier carpeta del repositorio
cd "$(dirname "$0")/.." || exit 2
PAT="['\"](triplesoc-alerts-|wazuh-alerts-|wazuh-monitoring-|rule\.(level|id|groups|description|mitre)['\"]|agent\.(id|name|ip)['\"])"
CONSUMERS=(triplesoc-bff/bff.py triplesoc-responder/responder.py triplesoc-incidents/incidents.py triplesoc-rulesmith/rulesmith.py
           triplesoc-dashboard/overlay/triplesoc-nav.js triplesoc-dashboard/overlay/triplesoc-incidents-ui.js
           triplesoc-dashboard/overlay/triplesoc-guardian-ui.js triplesoc-dashboard/overlay/triplesoc-assistant.js
           triplesoc-dashboard/overlay/triplesoc-rules-ui.js triplesoc-dashboard/saved-objects/triplesoc-overview.js)
# Índices propios de TripleSOC (triplesoc-incidents*) guardan agent.id con nuestra forma: no son de Wazuh.
# Si la consulta ocupa varias líneas, se marca la línea con el comentario "índice propio TripleSOC".
OWN="índice propio TripleSOC|RESPONSES_INDEX|GUARDIAN_INDEX|RULES_INDEX|INCIDENTS_INDEX|IDX\.(resp|inc|set|rules)|triplesoc-incidents"

bad=$(grep -nE "$PAT" "${CONSUMERS[@]}" | grep -vE "$OWN")
for f in schema/triplesoc-schema.json schema/tsoc_schema.py triplesoc-dashboard/overlay/triplesoc-schema.js; do
  [ -f "$f" ] || bad+=$'\n'"$f: falta el archivo de la capa traductora"
done
bad=$(printf '%s' "$bad" | sed '/^$/d')
if [ -z "$bad" ]; then
  echo "schema-lint: VERDE · ${#CONSUMERS[@]} consumidores sin índices ni campos de Wazuh escritos a mano"; exit 0
fi
echo "schema-lint: ROJO · usar la capa traductora en lugar de estos literales:"
printf '%s\n' "$bad" | sed 's/^/  /'
exit 1
