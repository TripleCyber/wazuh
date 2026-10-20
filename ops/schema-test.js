// Fase 2 · prueba de la capa traductora del dashboard (sin red, con el node de la imagen del dashboard):
//   docker run --rm --network none -v /opt/triplesoc/src:/src:ro --entrypoint /usr/share/wazuh-dashboard/node/bin/node \
//     triplesoc/wazuh-dashboard:<tag> /src/ops/schema-test.js
// Incrusta el contrato como lo hace apply-branding.sh y compara con lo que antes estaba escrito a mano.
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const root = process.argv[2] || path.join(__dirname, '..');
const json = fs.readFileSync(path.join(root, 'schema/triplesoc-schema.json'), 'utf8').trim();
const src = fs.readFileSync(path.join(root, 'triplesoc-dashboard/overlay/triplesoc-schema.js'), 'utf8');
const box = { window: {}, console };
vm.runInNewContext(src.replace('/*__TSOC_SCHEMA_JSON__*/null', json), box);
const TS = box.window.TSOC_SCHEMA;
let fails = 0;
function check(name, got, want) {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (!ok) fails++;
  console.log('  ' + (ok ? 'OK  ' : 'FAIL') + '  ' + name + (ok ? '' : '\n        obtenido: ' + JSON.stringify(got) + '\n        esperado: ' + JSON.stringify(want)));
}
if (!TS) { console.log('RESULTADO: ROJO (window.TSOC_SCHEMA no se definió)'); process.exit(1); }
console.log('Capa traductora (dashboard) · contrato ' + TS.contract + ' · adaptador ' + TS.adapter);
check('índice de alertas', TS.idx.alerts, 'triplesoc-alerts-*');
check('índice de monitorización', TS.idx.monitoring, 'wazuh-monitoring-*');
check('DQL Anonymous / Alerts', TS.kql.critical, 'rule.level >= 12');
check('DQL Verified', TS.kql.high, 'rule.level >= 7 and rule.level < 12');
check('DQL Secure', TS.kql.low, 'rule.level < 7');
check('DQL Audit/Endpoint (< 12)', TS.kql.below(TS.CRITICAL), 'rule.level < 12');
check('contador Alerts (DSL)', TS.sevGte(TS.CRITICAL), { range: { 'rule.level': { gte: 12 } } });
check('columnas de Discover', TS.columns.join(','), 'agent.name,rule.description,rule.level');
check('_source isla roja', TS.src('timestamp', 'agent_name', 'rule_description', 'severity'), ['timestamp', 'agent.name', 'rule.description', 'rule.level']);
check('term rule.groups', TS.term('rule_groups', 'vulnerability-detector'), { term: { 'rule.groups': 'vulnerability-detector' } });
check('campos sueltos', [TS.f.agent_id, TS.f.rule_id, TS.f.agent_name, TS.f.severity], ['agent.id', 'rule.id', 'agent.name', 'rule.level']);
check('severity(doc)', TS.severity({ rule: { level: 12 } }), 12);
console.log('RESULTADO: ' + (fails ? 'ROJO' : 'VERDE') + ' (' + fails + ' fallos)');
process.exit(fails ? 1 : 0);
