/* ==== TripleSOC schema ====
   Capa traductora del dashboard: las pantallas TripleSOC no escriben a mano el índice de alertas
   ni los campos de Wazuh (rule.level, agent.name...), los piden aquí. apply-branding.sh pega el
   contrato schema/triplesoc-schema.json en lugar del marcador y AÑADE este módulo al final de
   core.entry.js ANTES que los demás. Con Wazuh 5.x solo cambian este archivo y el JSON. */
;(function () {
  'use strict';
  if (window.TSOC_SCHEMA) return;
  var S = /*__TSOC_SCHEMA_JSON__*/null;
  if (!S || S.adapter !== 'wazuh-4.x') { console.error('[TripleSOC] contrato de esquema ausente o adaptador sin implementar'); return; }
  var F = S.fields, CRIT = S.severity_bands.critical, HIGH = S.severity_bands.high;
  function rng(gte, lt) {
    var r = {}; if (gte != null) r.gte = gte; if (lt != null) r.lt = lt;
    var o = {}; o[F.severity] = r; return { range: o };
  }
  window.TSOC_SCHEMA = {
    contract: S.contract, adapter: S.adapter, raw: S,
    idx: { alerts: S.alerts_index, legacy: S.legacy_alerts_index, monitoring: S.monitoring_index },
    f: F, CRITICAL: CRIT, HIGH: HIGH,
    // Consultas del indexer (DSL)
    sevGte: function (n) { return rng(n); },
    sevRange: rng,
    term: function (name, v) { var o = {}; o[F[name] || name] = v; return { term: o }; },
    src: function () { return Array.prototype.map.call(arguments, function (n) { return F[n] || n; }); },
    // Consultas DQL (Discover). Bandas: critical >= 12, high 7-11, low < 7.
    kql: {
      critical: F.severity + ' >= ' + CRIT,
      high: F.severity + ' >= ' + HIGH + ' and ' + F.severity + ' < ' + CRIT,
      low: F.severity + ' < ' + HIGH,
      below: function (n) { return F.severity + ' < ' + n; }
    },
    // Columnas de la lista de alertas en Discover
    columns: [F.agent_name, F.rule_description, F.severity],
    // Documento del indexer -> forma canónica TripleSOC (en 4.x es la misma)
    normalize: function (doc) { return doc; },
    severity: function (doc) { return Number((doc && doc.rule && doc.rule.level) || 0); }
  };
})();
