// TripleSOC · Security Overview: tablero nativo (objetos guardados, sin tocar código de Wazuh).
// Uso: abrir el dashboard con sesión iniciada, pegar este archivo en la consola del navegador.
// Solo crea/sobrescribe objetos con id "triplesoc-overview-*"; para quitarlo basta con borrarlos.
// Definiciones (provisionales, ajustables aquí):
//   Zonas: Anonymous = nivel >= 12, Verified = 7-11, Secure = 0-6.
//   Eventos: Threat = nivel >= 12; Audit = auditoría/integridad/autenticación (< 12); Endpoint = resto de agentes.
// Índice, campos y bandas salen de la capa traductora del dashboard (window.TSOC_SCHEMA): si cambian,
// basta con volver a pegar este archivo para regenerar el tablero.
(async () => {
  const TS = window.TSOC_SCHEMA;
  if (!TS) throw new Error('Falta la capa traductora TripleSOC (window.TSOC_SCHEMA): ¿dashboard sin la imagen TripleSOC?');
  const ALERTS = TS.idx.alerts;
  const AGENTS = 'triplesoc-incidents-agents';
  const C = { red: '#BB2227', green: '#1AA54A', blue: '#3B82F6', purple: '#8B5CF6', amber: '#D97706', gray: '#6B7280' };
  const AUDIT = `${TS.f.rule_groups}:(syscheck or policy_changed or account_changed or audit or authentication_success or authentication_failed or authentication_failures)`;
  const Q = {
    anonymous: TS.kql.critical,
    verified: TS.kql.high,
    secure: TS.kql.low,
    threat: TS.kql.critical,
    audit: `${TS.kql.below(TS.CRITICAL)} and ${AUDIT}`,
    endpoint: `${TS.kql.below(TS.CRITICAL)} and not ${TS.f.agent_id}:"000" and not ${AUDIT}`,
  };
  const kq = (query) => ({ query, language: 'kuery' });
  let n = 0; const uid = () => `tsoc-${++n}`;

  const series = (label, color, metrics, filter = '', extra = {}) => ({
    id: uid(), label, color, metrics, filter: kq(filter),
    split_mode: 'everything', split_color_mode: 'opensearchDashboards', separate_axis: 0, axis_position: 'right',
    formatter: 'number', chart_type: 'line', line_width: 2, point_size: 0, fill: 0.25, stacked: 'none',
    override_index_pattern: 0, series_drop_last_bucket: 0, hidden: false, ...extra,
  });
  const count = () => [{ id: uid(), type: 'count' }];

  const tsvb = (id, title, params) => ({
    type: 'visualization', id,
    attributes: {
      title, description: '', version: 1, uiStateJSON: '{}',
      visState: JSON.stringify({ title, type: 'metrics', aggs: [], params: {
        id: uid(), index_pattern: ALERTS, time_field: TS.f.timestamp, interval: '', axis_position: 'left',
        axis_formatter: 'number', axis_scale: 'normal', show_legend: 1, show_grid: 1, tooltip_mode: 'show_all',
        drop_last_bucket: 0, isModelInvalid: false, filter: kq(''), background_color_rules: [], ...params } }),
      kibanaSavedObjectMeta: { searchSourceJSON: '{}' },
    },
    references: [],
  });

  // Tarjeta de zona: número de eventos de la zona + % del total.
  const zone = (id, title, query, color) => tsvb(id, title, {
    type: 'metric', time_range_mode: 'entire_time_range',
    series: [
      series(title, color, count(), query),
      series('% of all events', color, [{ id: uid(), type: 'filter_ratio', numerator: kq(query), denominator: kq('*'), metric_agg: 'count' }], '', { formatter: 'percent' }),
    ],
  });
  // Tarjeta de agentes: inventario que triplesoc-responder copia de la API de Wazuh cada 5 min (un documento por
  // equipo, sin el 000 del manager). Sustituye a wazuh-monitoring, que escribía el plugin de Wazuh del dashboard.
  const agents = (id, title, query, color) => tsvb(id, title, {
    // ignore_global_filter: los filtros del tablero (nivel, agente) son de alertas, no del inventario.
    type: 'metric', index_pattern: AGENTS, time_field: 'updated_at', time_range_mode: 'entire_time_range', ignore_global_filter: 1,
    series: [series(title, color, [{ id: uid(), type: 'cardinality', field: 'id' }],
      `kind:agent and not id:"000"${query ? ` and ${query}` : ''}`)],
  });
  const events = (id, title, query, color) => tsvb(id, title, {
    type: 'metric', time_range_mode: 'entire_time_range',
    series: [series(title, color, count(), query)],
  });

  const objects = [
    zone('triplesoc-overview-zone-anonymous', 'Anonymous Zone · high severity (12+)', Q.anonymous, C.red),
    zone('triplesoc-overview-zone-verified', 'Verified Zone · medium severity (7-11)', Q.verified, C.blue),
    zone('triplesoc-overview-zone-secure', 'Secure Zone · low severity (0-6)', Q.secure, C.green),
    agents('triplesoc-overview-agents-total', 'Total agents', '', C.blue),
    agents('triplesoc-overview-agents-active', 'Active', 'status:active', C.green),
    agents('triplesoc-overview-agents-disconnected', 'Disconnected', 'status:disconnected', C.red),
    agents('triplesoc-overview-agents-pending', 'Pending', 'status:(pending or never_connected)', C.amber),
    events('triplesoc-overview-events-threat', 'Threat events', Q.threat, C.red),
    events('triplesoc-overview-events-audit', 'Audit events', Q.audit, C.blue),
    events('triplesoc-overview-events-endpoint', 'Endpoint events', Q.endpoint, C.purple),
    tsvb('triplesoc-overview-timeline', 'Events Timeline', {
      type: 'timeseries', time_range_mode: 'entire_time_range', interval: 'auto', legend_position: 'top',
      series: [
        series('Threats', C.red, count(), Q.threat),
        series('Audit', C.blue, count(), Q.audit),
        series('Endpoint', C.purple, count(), Q.endpoint),
      ],
    }),
    {
      type: 'visualization', id: 'triplesoc-overview-attacker-origins',
      attributes: {
        title: 'Attacker Origins', description: 'Geolocalización de la IP origen de las alertas', version: 1, uiStateJSON: '{}',
        visState: JSON.stringify({ title: 'Attacker Origins', type: 'tile_map', params: {
          colorSchema: 'Reds', mapType: 'Scaled Circle Markers', isDesaturated: true, addTooltip: true,
          heatClusterSize: 1.5, legendPosition: 'bottomright', mapZoom: 2, mapCenter: [20, 0],
          wms: { enabled: false, options: { format: 'image/png', transparent: true } },
        }, aggs: [
          { id: '1', enabled: true, type: 'count', schema: 'metric', params: {} },
          { id: '2', enabled: true, type: 'geohash_grid', schema: 'segment', params: {
            field: 'GeoLocation.location', autoPrecision: true, isFilteredByCollar: true, useGeocentroid: true,
            mapZoom: 2, mapCenter: [20, 0], precision: 2 } },
        ] }),
        kibanaSavedObjectMeta: { searchSourceJSON: JSON.stringify({ query: kq(''), filter: [], indexRefName: 'kibanaSavedObjectMeta.searchSourceJSON.index' }) },
      },
      references: [{ name: 'kibanaSavedObjectMeta.searchSourceJSON.index', type: 'index-pattern', id: ALERTS }],
    },
    {
      type: 'visualization', id: 'triplesoc-overview-filters',
      attributes: {
        title: 'Filters', description: '', version: 1, uiStateJSON: '{}',
        visState: JSON.stringify({ title: 'Filters', type: 'input_control_vis', aggs: [], params: {
          controls: [
            { id: '1', fieldName: TS.f.severity, label: 'Severity (level)', type: 'range', parent: '',
              options: { decimalPlaces: 0, step: 1 }, indexPatternRefName: 'control_0_index_pattern' },
            { id: '2', fieldName: TS.f.agent_name, label: 'Agent', type: 'list', parent: '',
              options: { type: 'terms', multiselect: true, dynamicOptions: true, size: 10, order: 'desc' },
              indexPatternRefName: 'control_1_index_pattern' },
          ],
          updateFiltersOnChange: true, useTimeFilter: true, pinFilters: false,
        } }),
        kibanaSavedObjectMeta: { searchSourceJSON: '{}' },
      },
      references: [
        { name: 'control_0_index_pattern', type: 'index-pattern', id: ALERTS },
        { name: 'control_1_index_pattern', type: 'index-pattern', id: ALERTS },
      ],
    },
  ];

  // Distribución (rejilla de 48 columnas), imitando el diseño de referencia.
  const layout = [
    ['triplesoc-overview-filters', 0, 0, 48, 5, false],
    ['triplesoc-overview-zone-anonymous', 0, 5, 16, 8, true],
    ['triplesoc-overview-zone-verified', 16, 5, 16, 8, true],
    ['triplesoc-overview-zone-secure', 32, 5, 16, 8, true],
    ['triplesoc-overview-agents-total', 0, 13, 12, 5, true],
    ['triplesoc-overview-agents-active', 12, 13, 12, 5, true],
    ['triplesoc-overview-agents-disconnected', 24, 13, 12, 5, true],
    ['triplesoc-overview-agents-pending', 36, 13, 12, 5, true],
    ['triplesoc-overview-events-threat', 0, 18, 10, 6, true],
    ['triplesoc-overview-events-audit', 10, 18, 10, 6, true],
    ['triplesoc-overview-events-endpoint', 20, 18, 10, 6, true],
    ['triplesoc-overview-attacker-origins', 30, 18, 18, 20, false],
    ['triplesoc-overview-timeline', 0, 24, 30, 14, false],
  ];
  const panels = layout.map(([, x, y, w, h, hideTitle], i) => ({
    version: '2.19.5', gridData: { x, y, w, h, i: String(i + 1) }, panelIndex: String(i + 1),
    embeddableConfig: hideTitle ? { hidePanelTitles: true } : {}, panelRefName: `panel_${i}`,
  }));
  objects.push({
    type: 'dashboard', id: 'triplesoc-overview',
    attributes: {
      title: 'TripleSOC · Security Overview', description: 'Real-time threat monitoring and security operations',
      version: 1, panelsJSON: JSON.stringify(panels), optionsJSON: JSON.stringify({ useMargins: true, hidePanelTitles: false }),
      timeRestore: true, timeFrom: 'now-24h', timeTo: 'now', refreshInterval: { pause: false, value: 30000 },
      kibanaSavedObjectMeta: { searchSourceJSON: JSON.stringify({ query: kq(''), filter: [] }) },
    },
    references: layout.map(([id], i) => ({ name: `panel_${i}`, type: 'visualization', id })),
  });

  const ndjson = objects.map((o) => JSON.stringify(o)).join('\n');
  const form = new FormData();
  form.append('file', new Blob([ndjson], { type: 'application/ndjson' }), 'triplesoc-overview.ndjson');
  const res = await fetch('/api/saved_objects/_import?overwrite=true', { method: 'POST', headers: { 'osd-xsrf': 'true' }, body: form });
  const out = await res.json();
  console.log('[TripleSOC] import', res.status, out);
  return { status: res.status, success: out.success, count: out.successCount, errors: out.errors };
})();
