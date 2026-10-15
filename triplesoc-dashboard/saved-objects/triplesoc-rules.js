// TripleSOC · AI Rules: tablero vacío que sirve de ruta para la pantalla AI Rules
// (overlay/triplesoc-rules-ui.js la dibuja encima). Uso: pegar en la consola del dashboard con sesión iniciada.
// Solo crea el objeto si no existe; para quitarlo basta con borrar el dashboard "triplesoc-rules".
(async () => {
  const url = '/api/saved_objects/dashboard/triplesoc-rules';
  const h = { 'osd-xsrf': 'true', 'content-type': 'application/json' };
  if ((await fetch(url, { headers: h })).status === 200) return console.log('triplesoc-rules ya existe');
  const r = await fetch(url, { method: 'POST', headers: h, body: JSON.stringify({ attributes: {
    title: 'TripleSOC · AI Rules', description: 'Detection rules drafted by AI and approved by analysts',
    panelsJSON: '[]', optionsJSON: '{"useMargins":true,"hidePanelTitles":false}', version: 1, timeRestore: false,
    kibanaSavedObjectMeta: { searchSourceJSON: '{"query":{"query":"","language":"kuery"},"filter":[]}' },
  } }) });
  console.log('triplesoc-rules:', r.status);
})();
