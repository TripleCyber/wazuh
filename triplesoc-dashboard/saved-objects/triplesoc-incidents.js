// TripleSOC · Incidents: tablero vacío que sirve de ruta para la pantalla Incidents
// (overlay/triplesoc-incidents-ui.js la dibuja encima). Uso: pegar en la consola del dashboard con sesión iniciada.
// Solo crea el objeto si no existe; para quitarlo basta con borrar el dashboard "triplesoc-incidents".
(async () => {
  const url = '/api/saved_objects/dashboard/triplesoc-incidents';
  const h = { 'osd-xsrf': 'true', 'content-type': 'application/json' };
  if ((await fetch(url, { headers: h })).status === 200) return console.log('triplesoc-incidents ya existe');
  const r = await fetch(url, { method: 'POST', headers: h, body: JSON.stringify({ attributes: {
    title: 'TripleSOC · Incidents', description: 'Alerts automatically correlated into incidents',
    panelsJSON: '[]', optionsJSON: '{"useMargins":true,"hidePanelTitles":false}', version: 1, timeRestore: false,
    kibanaSavedObjectMeta: { searchSourceJSON: '{"query":{"query":"","language":"kuery"},"filter":[]}' },
  } }) });
  console.log('triplesoc-incidents:', r.status);
})();
