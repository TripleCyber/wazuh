/* ==== TripleSOC incidents ====
   Pantalla "Incidents": incidentes que el servicio triplesoc-incidents correlaciona a partir de las alertas.
   Se muestra sobre el tablero guardado "triplesoc-incidents" (ruta /app/dashboards#/view/triplesoc-incidents).
   apply-branding.sh lo AÑADE al final de core.entry.js: no modifica código existente.
   Lectura: /internal/search/opensearch (permisos de índice del usuario).
   Triage (estado, responsable, notas): _update con la sesión del propio usuario vía la consola del dashboard,
   así cada cambio queda hecho con su identidad. Si la escritura no está permitida, la pantalla queda en solo lectura. */
;(function () {
  'use strict';
  var TS = window.TSOC_SCHEMA; // capa traductora (triplesoc-schema.js): índice y campos de alertas
  if (!TS) return;
  if (window.__tsocInc) return;
  window.__tsocInc = true;

  var INDEX = 'triplesoc-incidents';
  var RESP_INDEX = 'triplesoc-incidents-responses'; // recomendaciones del servicio triplesoc-responder
  var ROUTE = /^\/app\/dashboards.*view\/triplesoc-incidents/;
  var WINDOW_MIN = 30;
  var TACTICS = ['Initial Access', 'Execution', 'Persistence', 'Privilege Escalation', 'Defense Evasion',
    'Credential Access', 'Discovery', 'Lateral Movement', 'Collection', 'Command and Control', 'Exfiltration', 'Impact'];
  var STATUS = { new: 'New', investigating: 'Investigating', resolved: 'Resolved', false_positive: 'False positive' };
  var TABS = [
    { id: 'open', label: 'Open', q: { terms: { status: ['new', 'investigating'] } } },
    { id: 'new', label: 'New', q: { term: { status: 'new' } } },
    { id: 'investigating', label: 'Investigating', q: { term: { status: 'investigating' } } },
    { id: 'closed', label: 'Closed', q: { terms: { status: ['resolved', 'false_positive'] } } },
    { id: 'all', label: 'All', q: { match_all: {} } }
  ];
  var S = { tab: 'open', q: '', items: [], total: 0, sel: null, rec: null, user: null, err: null, kpi: null, busy: false, loadedAt: 0, writeErr: null };

  // ---------------------------------------------------------------- datos
  function search(body, index) {
    return fetch('/internal/search/opensearch', {
      method: 'POST', credentials: 'same-origin',
      headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify({ params: { index: index || INDEX, body: body } })
    }).then(function (r) {
      if (!r.ok) return r.json().catch(function () { return {}; }).then(function (j) {
        var msg = JSON.stringify(j); throw new Error(/index_not_found/.test(msg) ? 'NO_INDEX' : 'HTTP ' + r.status);
      });
      return r.json();
    }).then(function (j) { return j.rawResponse; });
  }
  function total(h) { return typeof h.total === 'number' ? h.total : (h.total && h.total.value) || 0; }

  function load() {
    if (S.busy) return;
    S.busy = true;
    var tab = TABS.filter(function (t) { return t.id === S.tab; })[0];
    var must = [tab.q];
    if (S.q) must.push({ simple_query_string: { query: S.q + '*', fields: ['title', 'incident_id', 'agent.name', 'rules.description', 'mitre.tactics'], default_operator: 'and' } });
    var list = search({ size: 200, track_total_hits: true, query: { bool: { filter: must } },
      sort: [{ severity_rank: 'desc' }, { last_seen: 'desc' }] });
    var since = new Date(Date.now() - 7 * 864e5).toISOString();
    var kpi = search({ size: 0, track_total_hits: true, aggs: {
      open: { filter: { terms: { status: ['new', 'investigating'] } }, aggs: { hi: { filter: { range: { severity_rank: { gte: 3 } } } } } },
      week: { filter: { range: { first_seen: { gte: since } } }, aggs: { alerts: { sum: { field: 'alert_count' } } } }
    } });
    var times = search({ size: 1000, _source: ['created_at', 'acknowledged_at', 'resolved_at'],
      query: { bool: { filter: [{ exists: { field: 'acknowledged_at' } }, { range: { acknowledged_at: { gte: 'now-30d' } } }] } } });
    // El incidente abierto en el panel se relee aparte: tras resolverlo ya no está en la pestaña "Open".
    var sel = S.sel ? search({ size: 1, query: { term: { incident_id: S.sel.incident_id } } }) : Promise.resolve(null);
    Promise.all([list, kpi, times, sel]).then(function (r) {
      S.err = null;
      S.items = r[0].hits.hits.map(function (h) { return h._source; });
      S.total = total(r[0].hits);
      var a = r[1].aggregations, ack = [], res = [];
      r[2].hits.hits.forEach(function (h) {
        var s = h._source, c = Date.parse(s.created_at);
        if (s.acknowledged_at) ack.push(Date.parse(s.acknowledged_at) - c);
        if (s.resolved_at) res.push(Date.parse(s.resolved_at) - c);
      });
      var avg = function (xs) { return xs.length ? xs.reduce(function (x, y) { return x + y; }, 0) / xs.length : null; };
      S.kpi = { open: a.open.doc_count, high: a.open.hi.doc_count, weekInc: a.week.doc_count,
        weekAlerts: a.week.alerts.value || 0, mtta: avg(ack), mttr: avg(res) };
      if (S.sel && r[3] && r[3].hits.hits.length) S.sel = r[3].hits.hits[0]._source;
    }).catch(function (e) { S.err = e.message; S.items = []; S.kpi = null; })
      .then(function () { S.busy = false; S.loadedAt = Date.now(); render(); loadRec(); });
  }

  // Recomendación de respuesta del incidente abierto en el panel (si el servicio ya la generó).
  function loadRec() {
    var id = S.sel && S.sel.incident_id;
    if (!id) { S.rec = null; return; }
    search({ size: 1, query: { term: { incident_id: id } } }, RESP_INDEX).then(function (r) {
      return r.hits.hits.length ? r.hits.hits[0]._source : null;
    }).catch(function () { return null; }).then(function (rec) {
      if (S.sel && S.sel.incident_id === id) { S.rec = rec; render(); }
    });
  }

  // Aprobar o rechazar la recomendación: queda registrado quién y cuándo, con la sesión del usuario.
  function decide(rec, status) {
    var path = RESP_INDEX + '/_update/' + encodeURIComponent(rec.incident_id) + '?refresh=wait_for';
    S.writeErr = null;
    return fetch('/api/console/proxy?path=' + encodeURIComponent(path) + '&method=POST', {
      method: 'POST', credentials: 'same-origin',
      headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      // Deshacer se anota aparte: no pisa quién aprobó la acción original.
      body: JSON.stringify({ doc: status === 'undo_requested'
        ? { status: status, undo_by: S.user || 'analyst', undo_at: new Date().toISOString() }
        : { status: status, decided_by: S.user || 'analyst', decided_at: new Date().toISOString() } })
    }).then(function (r) {
      if (!r.ok) throw new Error(r.status === 403 ? 'You do not have permission to decide on responses.' : 'Update failed (HTTP ' + r.status + ').');
      loadRec();
      // El servicio ejecuta en su siguiente pasada: se relee unas veces para mostrar el resultado sin esperar al refresco.
      [3000, 8000, 15000, 30000].forEach(function (ms) { setTimeout(loadRec, ms); });
    }).catch(function (e) { S.writeErr = e.message; render(); });
  }

  function triage(inc, p) {
    var now = new Date().toISOString();
    var src = 'def s = ctx._source; s.updated_at = params.now;' +
      'if (params.status != null) { s.status = params.status; }' +
      'if (params.assignee != null) { s.assignee = params.assignee; }' +
      'if (params.ack && s.acknowledged_at == null) { s.acknowledged_at = params.now; }' +
      'if (params.close != null) { s.resolved_at = params.now; s.resolution = params.close; }' +
      'if (params.reopen) { s.resolved_at = null; s.resolution = null; }' +
      'if (params.note != null) { if (s.notes == null) { s.notes = []; } s.notes.add(params.note); }';
    var params = Object.assign({ now: now, status: null, assignee: null, ack: false, close: null, reopen: false, note: null }, p);
    var path = INDEX + '/_update/' + encodeURIComponent(inc.incident_id) + '?refresh=wait_for';
    S.writeErr = null;
    return fetch('/api/console/proxy?path=' + encodeURIComponent(path) + '&method=POST', {
      method: 'POST', credentials: 'same-origin',
      headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify({ script: { lang: 'painless', source: src, params: params } })
    }).then(function (r) {
      if (!r.ok) throw new Error(r.status === 403 ? 'You do not have permission to update incidents.' : 'Update failed (HTTP ' + r.status + ').');
      S.loadedAt = 0; load();
    }).catch(function (e) { S.writeErr = e.message; render(); });
  }

  function me() {
    if (S.user) return S.user;
    fetch('/api/v1/configuration/account', { credentials: 'same-origin' }).then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) { S.user = (j && j.data && j.data.user_name) || 'analyst'; }).catch(function () { S.user = 'analyst'; });
    return null;
  }

  // ---------------------------------------------------------------- utilidades
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function ago(iso) {
    if (!iso) return '—';
    var s = Math.max(0, (Date.now() - Date.parse(iso)) / 1000);
    if (s < 60) return 'just now'; if (s < 3600) return Math.floor(s / 60) + ' min ago';
    if (s < 86400) return Math.floor(s / 3600) + ' h ago'; return Math.floor(s / 86400) + ' d ago';
  }
  function when(iso) { return iso ? new Date(iso).toLocaleString() : '—'; }
  function dur(ms) {
    if (ms == null) return '—';
    var m = ms / 60000; if (m < 60) return Math.max(1, Math.round(m)) + ' min';
    var h = m / 60; if (h < 48) return h.toFixed(1) + ' h'; return (h / 24).toFixed(1) + ' d';
  }
  function num(n) { return Number(n || 0).toLocaleString(); }
  function sev(s) { return '<span class="tsocInc__sev tsocInc__sev--' + esc(s) + '">' + esc(s || '—') + '</span>'; }
  function st(s) { return '<span class="tsocInc__st tsocInc__st--' + esc(s) + '">' + esc(STATUS[s] || s) + '</span>'; }
  function discover(inc) {
    var ids = (inc.rules || []).map(function (r) { return r.id; }).join(' or ');
    var q = TS.f.agent_id + ':"' + inc.agent.id + '"' + (ids ? ' and ' + TS.f.rule_id + ':(' + ids + ')' : '');
    var from = new Date(Date.parse(inc.first_seen) - 60000).toISOString(), to = new Date(Date.parse(inc.last_seen) + 60000).toISOString();
    return "/app/data-explorer/discover#?_a=(discover:(columns:!(" + TS.columns.join(',') + "),isDirty:!f,sort:!())," +
      "metadata:(indexPattern:'" + TS.idx.alerts + "',view:discover))&_g=(filters:!(),refreshInterval:(pause:!t,value:0)," +
      "time:(from:'" + from + "',to:'" + to + "'))&_q=(filters:!(),query:(language:kuery,query:'" + q.replace(/'/g, "!'") + "'))";
  }

  // ---------------------------------------------------------------- vista
  var root = null;
  function mount() {
    if (root) return root;
    root = document.createElement('div');
    root.id = 'tsoc-inc';
    root.className = 'tsocInc';
    root.addEventListener('click', onClick);
    root.addEventListener('input', function (e) {
      if (e.target.matches('[data-search]')) { S.q = e.target.value.trim(); clearTimeout(root._t); root._t = setTimeout(load, 300); }
    });
    root.addEventListener('keydown', function (e) { if (e.key === 'Escape' && S.sel) { S.sel = null; render(); } });
    document.body.appendChild(root);
    S.loadedAt = 0; load();
    return root;
  }
  function unmount() { if (root) { root.remove(); root = null; S.sel = null; } }

  function kpis() {
    var k = S.kpi;
    if (!k) return '';
    var red = k.weekAlerts ? Math.max(0, Math.round((1 - k.weekInc / k.weekAlerts) * 100)) : 0;
    return '<div class="tsocInc__kpis">' +
      card('Open incidents', num(k.open), k.high + ' high or critical', k.high ? 'red' : 'green') +
      card('Noise reduction (7 d)', red + '%', num(k.weekAlerts) + ' alerts → ' + num(k.weekInc) + ' incidents', 'green') +
      card('MTTA', dur(k.mtta), 'mean time to acknowledge (30 d)', 'blue') +
      card('MTTR', dur(k.mttr), 'mean time to resolve (30 d)', 'purple') + '</div>';
  }
  function card(label, value, sub, color) {
    return '<div class="tsocInc__kpi tsocInc__kpi--' + color + '"><div class="tsocInc__kpiLabel">' + esc(label) + '</div>' +
      '<div class="tsocInc__kpiValue">' + esc(value) + '</div><div class="tsocInc__kpiSub">' + esc(sub) + '</div></div>';
  }
  function table() {
    if (S.err === 'NO_INDEX') return empty('The correlation service has not created any incident yet.', 'Incidents appear here as soon as the TripleSOC Incidents service processes the first alerts.');
    if (S.err) return empty('Incidents could not be loaded.', S.err);
    if (!S.items.length) return empty(S.busy ? 'Loading…' : 'No incidents in this view.', S.q ? 'Try another search.' : '');
    var rows = S.items.map(function (i) {
      var tac = (i.mitre && i.mitre.tactics || []).slice(0, 3).map(function (t) { return '<span class="tsocInc__chip">' + esc(t) + '</span>'; }).join('');
      return '<tr data-open="' + esc(i.incident_id) + '"' + (S.sel && S.sel.incident_id === i.incident_id ? ' class="is-sel"' : '') + '>' +
        '<td>' + sev(i.severity) + '</td>' +
        '<td><div class="tsocInc__title">' + esc(i.title) + (i.multi_stage ? ' <span class="tsocInc__ms">multi-stage</span>' : '') + '</div>' +
        '<div class="tsocInc__sub">' + esc(i.incident_id) + ' · score ' + esc(i.score) + '</div></td>' +
        '<td>' + esc(i.agent && i.agent.name) + '</td>' +
        '<td class="tsocInc__num">' + num(i.alert_count) + '</td>' +
        '<td>' + (tac || '<span class="tsocInc__muted">—</span>') + '</td>' +
        '<td title="' + esc(when(i.last_seen)) + '">' + esc(ago(i.last_seen)) + '</td>' +
        '<td>' + st(i.status) + '</td>' +
        '<td>' + (i.assignee ? esc(i.assignee) : '<span class="tsocInc__muted">Unassigned</span>') + '</td></tr>';
    }).join('');
    return '<table class="tsocInc__table"><thead><tr><th>Severity</th><th>Incident</th><th>Endpoint</th><th class="tsocInc__num">Alerts</th>' +
      '<th>MITRE tactics</th><th>Last activity</th><th>Status</th><th>Assignee</th></tr></thead><tbody>' + rows + '</tbody></table>' +
      (S.total > S.items.length ? '<div class="tsocInc__more">Showing ' + S.items.length + ' of ' + num(S.total) + '</div>' : '');
  }
  function empty(t, s) { return '<div class="tsocInc__empty"><b>' + esc(t) + '</b><span>' + esc(s) + '</span></div>'; }

  function recBox() {
    var r = S.rec; if (!r) return '';
    var manual = r.action === 'manual_review';
    var how = { auto: 'Would run automatically', approval: 'Needs approval', manual: 'Manual review' }[r.decision] || r.decision;
    // mode "approve": el servicio ejecuta en el equipo lo que se apruebe aquí; "shadow": solo se registra.
    var live = r.mode === 'approve';
    var ran = { executing: 'Running on the endpoint…', executed: 'Executed', failed: 'Not executed', unsupported: 'Not executed',
      undo_requested: 'Undo requested…', undoing: 'Undoing on the endpoint…', undone: 'Undone', undo_failed: 'Undo not executed' }[r.status];
    var at = r.status === 'undone' ? r.undone_at : (r.status === 'executed' ? r.executed_at : null);
    // Tras un fallo se puede reintentar; lo ejecutado se puede deshacer.
    var next = { failed: ['approve', 'Retry'], executed: ['undo', 'Undo'], undo_failed: ['undo', 'Retry undo'] }[r.status];
    var state = r.status && r.status !== 'recommended'
      ? '<div class="tsocInc__recState tsocInc__recState--' + (r.status === 'rejected' ? 'rejected' : 'approved') + '">' +
        (r.status === 'rejected' ? 'Rejected' : 'Approved') + ' by ' + esc(r.decided_by) + ' · ' + esc(when(r.decided_at)) + '</div>' +
        (ran ? '<div class="tsocInc__recState tsocInc__recState--' + esc(r.status) + '">' + ran +
          (at ? ' · ' + esc(when(at)) : '') + '</div><div class="tsocInc__sub">' + esc(r.exec_result) + '</div>' : '') +
        (next ? '<div class="tsocInc__actions"><button data-act="' + next[0] + '" class="tsocInc__btn">' + next[1] + '</button></div>' : '')
      : (manual ? '' : '<div class="tsocInc__actions"><button data-act="approve" class="tsocInc__btn tsocInc__btn--primary">Approve</button>' +
        '<button data-act="reject" class="tsocInc__btn">Reject</button></div>');
    return '<h3>Recommended response</h3><div class="tsocInc__rec">' +
      '<div class="tsocInc__recTitle">' + esc(r.action_label) + (manual ? '' : ' <span class="tsocInc__sub">→ ' + esc(r.target) + '</span>') + '</div>' +
      '<div>' + esc(r.reason) + '</div>' +
      (manual ? '' : '<dl class="tsocInc__meta"><div><dt>Policy</dt><dd>' + esc(how) + '</dd></div>' +
        '<div><dt>Risk · confidence</dt><dd>' + esc(r.risk) + ' · ' + Math.round((r.confidence || 0) * 100) + '%</dd></div></dl>' +
        '<div class="tsocInc__sub">' + esc(r.decision_reason) + (r.undo ? ' Undo: ' + esc(r.undo) : '') + '</div>') +
      state +
      (manual ? '' : '<div class="tsocInc__sub tsocInc__recNote">' + (live
        ? 'Approving runs this action on the endpoint through its Wazuh agent.'
        : 'Shadow mode: the decision is recorded, nothing runs on the endpoint yet.') + '</div>') +
      '</div>';
  }

  function drawer() {
    var i = S.sel; if (!i) return '';
    var open = i.status === 'new' || i.status === 'investigating';
    var tset = (i.mitre && i.mitre.tactics) || [];
    var chain = TACTICS.map(function (t) { return '<li class="' + (tset.indexOf(t) >= 0 ? 'on' : '') + '">' + esc(t) + '</li>'; }).join('');
    var rules = (i.rules || []).map(function (r) {
      return '<tr><td class="tsocInc__num">' + esc(r.level) + '</td><td>' + esc(r.description) + '<div class="tsocInc__sub">rule ' + esc(r.id) + '</div></td><td class="tsocInc__num">' + num(r.count) + '</td></tr>';
    }).join('');
    var notes = (i.notes || []).slice().reverse().map(function (n) {
      return '<li><div class="tsocInc__sub">' + esc(n.by) + ' · ' + esc(when(n.at)) + '</div>' + esc(n.text) + '</li>';
    }).join('');
    var acts = open
      ? (i.status === 'new' || i.assignee !== S.user ? '<button data-act="take" class="tsocInc__btn tsocInc__btn--primary">Take ownership</button>' : '') +
        '<button data-act="resolve" class="tsocInc__btn">Resolve</button><button data-act="fp" class="tsocInc__btn">False positive</button>'
      : '<button data-act="reopen" class="tsocInc__btn">Reopen</button>';
    return '<aside class="tsocInc__drawer"><div class="tsocInc__dHead"><div>' + sev(i.severity) + ' ' + st(i.status) +
      '<h2>' + esc(i.title) + '</h2><div class="tsocInc__sub">' + esc(i.incident_id) + '</div></div>' +
      '<button data-act="close" class="tsocInc__x" aria-label="Close">×</button></div>' +
      '<div class="tsocInc__dBody">' +
      '<dl class="tsocInc__meta"><div><dt>Endpoint</dt><dd>' + esc(i.agent.name) + '<span class="tsocInc__sub"> ' + esc(i.agent.ip || '') + '</span></dd></div>' +
      '<div><dt>Risk score</dt><dd>' + esc(i.score) + ' / 100</dd></div>' +
      '<div><dt>Correlated alerts</dt><dd>' + num(i.alert_count) + ' (max level ' + esc(i.max_level) + ')</dd></div>' +
      '<div><dt>Assignee</dt><dd>' + esc(i.assignee || 'Unassigned') + '</dd></div>' +
      '<div><dt>First seen</dt><dd>' + esc(when(i.first_seen)) + '</dd></div>' +
      '<div><dt>Last activity</dt><dd>' + esc(when(i.last_seen)) + '</dd></div></dl>' +
      '<div class="tsocInc__actions">' + acts + '<a class="tsocInc__btn tsocInc__btn--ghost" href="' + esc(discover(i)) + '" data-nav>View alerts</a></div>' +
      (S.writeErr ? '<div class="tsocInc__warn">' + esc(S.writeErr) + '</div>' : '') +
      recBox() +
      '<h3>Attack chain (MITRE ATT&amp;CK)</h3><ol class="tsocInc__chain">' + chain + '</ol>' +
      (tset.length ? '' : '<div class="tsocInc__sub">No MITRE tactics mapped for these alerts.</div>') +
      '<h3>Rules involved</h3><table class="tsocInc__rules"><thead><tr><th>Lvl</th><th>Rule</th><th class="tsocInc__num">Alerts</th></tr></thead><tbody>' + rules + '</tbody></table>' +
      '<h3>Notes</h3><div class="tsocInc__note"><textarea data-note rows="2" placeholder="Add an investigation note…"></textarea>' +
      '<button data-act="note" class="tsocInc__btn">Add note</button></div><ul class="tsocInc__notes">' + (notes || '<li class="tsocInc__muted">No notes yet.</li>') + '</ul>' +
      '</div></aside>';
  }

  function render() {
    if (!root) return;
    var focus = document.activeElement && document.activeElement.matches && document.activeElement.matches('[data-search]');
    var draft = root.querySelector('[data-note]'); draft = draft ? draft.value : '';
    var tabs = TABS.map(function (t) { return '<button data-tab="' + t.id + '" class="' + (S.tab === t.id ? 'is-on' : '') + '">' + esc(t.label) + '</button>'; }).join('');
    root.innerHTML = '<div class="tsocInc__page">' +
      '<div class="tsocInc__head"><div><h1>Incidents</h1><p>Alerts automatically correlated into incidents · same endpoint and category within ' + WINDOW_MIN + ' min</p></div>' +
      '<button data-act="refresh" class="tsocInc__btn">' + (S.busy ? 'Refreshing…' : 'Refresh') + '</button></div>' +
      kpis() +
      '<div class="tsocInc__bar"><div class="tsocInc__tabs">' + tabs + '</div>' +
      '<input data-search type="search" placeholder="Search incidents, endpoints, rules, tactics" value="' + esc(S.q) + '"></div>' +
      '<div class="tsocInc__card">' + table() + '</div></div>' + drawer();
    root.classList.toggle('has-drawer', !!S.sel);
    if (focus) { var s = root.querySelector('[data-search]'); s.focus(); s.setSelectionRange(s.value.length, s.value.length); }
    var n = root.querySelector('[data-note]'); if (n && draft) n.value = draft;
  }

  function onClick(e) {
    var t = e.target.closest('[data-tab],[data-open],[data-act],[data-nav]');
    if (!t) return;
    if (t.hasAttribute('data-nav')) {
      if (e.button !== 0 || e.ctrlKey || e.metaKey || e.shiftKey) return;
      e.preventDefault(); history.pushState(null, '', t.getAttribute('href')); window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
      return;
    }
    if (t.hasAttribute('data-tab')) { S.tab = t.getAttribute('data-tab'); S.sel = null; load(); return; }
    if (t.hasAttribute('data-open')) {
      var id = t.getAttribute('data-open');
      S.sel = S.items.filter(function (i) { return i.incident_id === id; })[0] || null; S.rec = null; S.writeErr = null; render(); loadRec(); return;
    }
    var act = t.getAttribute('data-act'), inc = S.sel, user = me() || 'analyst';
    if (act === 'refresh') { load(); return; }
    if (act === 'close') { S.sel = null; S.rec = null; render(); return; }
    if (!inc) return;
    if (act === 'undo' && S.rec) {
      if (window.confirm('Undo "' + S.rec.action_label + '" on ' + S.rec.target + ' now?')) decide(S.rec, 'undo_requested');
      return;
    }
    if ((act === 'approve' || act === 'reject') && S.rec) {
      // En modo de ejecución, aprobar actúa de verdad sobre el equipo: se pide confirmación.
      if (act === 'approve' && S.rec.mode === 'approve' &&
          !window.confirm('Run "' + S.rec.action_label + '" on ' + S.rec.target + ' now?')) return;
      decide(S.rec, act === 'approve' ? 'approved' : 'rejected'); return;
    }
    if (act === 'take') triage(inc, { status: 'investigating', assignee: user, ack: true });
    if (act === 'resolve') triage(inc, { status: 'resolved', ack: true, close: 'resolved', assignee: inc.assignee ? null : user });
    if (act === 'fp') triage(inc, { status: 'false_positive', ack: true, close: 'false_positive', assignee: inc.assignee ? null : user });
    if (act === 'reopen') triage(inc, { status: 'investigating', reopen: true });
    if (act === 'note') {
      var ta = root.querySelector('[data-note]'), text = ta && ta.value.trim();
      if (text) { ta.value = ''; triage(inc, { note: { at: new Date().toISOString(), by: user, text: text.slice(0, 2000) } }); }
    }
  }

  // Coloca la pantalla sobre el área de la aplicación (debajo de la cabecera, a la derecha del menú anclado).
  function place() {
    var host = document.querySelector('.app-wrapper') || document.querySelector('#app-wrapper');
    var top = 48, left = 0;
    if (host) { var r = host.getBoundingClientRect(); top = Math.max(0, r.top); left = Math.max(0, r.left); }
    else {
      var hdr = document.querySelector('#globalHeaderBars'); if (hdr) top = hdr.getBoundingClientRect().bottom;
      var nav = document.querySelector('.euiCollapsibleNav'); if (nav && !document.querySelector('.euiOverlayMask')) left = nav.getBoundingClientRect().right;
    }
    root.style.top = top + 'px'; root.style.left = left + 'px';
  }

  function tick() {
    try {
      var here = location.pathname + decodeURIComponent(location.hash);
      if (!ROUTE.test(here)) { unmount(); return; }
      me(); mount();
      // Con carga directa o F5, el arranque del dashboard descarta el nodo: se vuelve a enganchar.
      if (!root.isConnected) document.body.appendChild(root);
      place();
      if (!S.busy && Date.now() - S.loadedAt > 30000 && !(root.querySelector('[data-note]') && root.querySelector('[data-note]').value)) load();
    } catch (err) { /* nunca romper la página */ }
  }
  setInterval(tick, 500);
})();
/* ==== fin TripleSOC incidents ==== */
