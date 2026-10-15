/* ==== TripleSOC rules ====
   Pantalla "AI Rules": reglas de detección que redacta el servicio triplesoc-rulesmith con IA.
   Se muestra sobre el tablero guardado "triplesoc-rules" (ruta /app/dashboards#/view/triplesoc-rules).
   apply-branding.sh lo AÑADE al final de core.entry.js: no modifica código existente.
   Reutiliza el aspecto de la pantalla Incidents (clases tsocInc__*).
   Pedir, aprobar, promover o desactivar solo cambia el estado del documento con la sesión del usuario;
   la instalación en Wazuh la hace el servicio, que valida y vuelve atrás si algo falla. */
;(function () {
  'use strict';
  if (window.__tsocRules) return;
  window.__tsocRules = true;

  var INDEX = 'triplesoc-incidents-rules';
  var ROUTE = /^\/app\/dashboards.*view\/triplesoc-rules/;
  var STATUS = {
    requested: 'Queued for AI', drafting: 'AI drafting…', revision_requested: 'Revision queued', proposed: 'Ready for review',
    invalid: 'Failed validation', skipped: 'Not detectable', rejected: 'Rejected', approved: 'Installing…',
    install_failed: 'Install failed', silent: 'Silent test', promote_requested: 'Promoting…', active: 'Active',
    disable_requested: 'Disabling…', disabled: 'Disabled'
  };
  var TONE = { proposed: 'investigating', silent: 'new', active: 'resolved', invalid: 'false_positive', install_failed: 'false_positive' };
  var SOURCE = { analyst: 'Analyst request', kev: 'CISA KEV' };
  var TABS = [
    { id: 'review', label: 'To review', s: ['proposed', 'invalid'] },
    { id: 'work', label: 'In progress', s: ['requested', 'drafting', 'revision_requested', 'approved', 'promote_requested', 'disable_requested', 'install_failed'] },
    { id: 'silent', label: 'Silent test', s: ['silent'] },
    { id: 'active', label: 'Active', s: ['active'] },
    { id: 'archive', label: 'Archive', s: ['rejected', 'skipped', 'disabled'] },
    { id: 'all', label: 'All', s: null }
  ];
  var S = { tab: 'review', items: [], kpi: null, sel: null, user: null, err: null, busy: false, loadedAt: 0, writeErr: null, info: null };

  // ---------------------------------------------------------------- datos
  function search(body) {
    return fetch('/internal/search/opensearch', {
      method: 'POST', credentials: 'same-origin',
      headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify({ params: { index: INDEX, body: body } })
    }).then(function (r) {
      if (!r.ok) return r.json().catch(function () { return {}; }).then(function (j) {
        throw new Error(/index_not_found/.test(JSON.stringify(j)) ? 'NO_INDEX' : 'HTTP ' + r.status);
      });
      return r.json();
    }).then(function (j) { return j.rawResponse; });
  }

  function load() {
    if (S.busy) return;
    S.busy = true;
    var tab = TABS.filter(function (t) { return t.id === S.tab; })[0];
    var filter = [{ term: { kind: 'rule' } }];
    if (tab.s) filter.push({ terms: { status: tab.s } });
    var list = search({ size: 200, query: { bool: { filter: filter } }, sort: [{ updated_at: 'desc' }] });
    var kpi = search({ size: 0, query: { term: { kind: 'rule' } }, aggs: { st: { terms: { field: 'status', size: 20 } },
      hits: { filter: { term: { status: 'silent' } }, aggs: { n: { sum: { field: 'hits_7d' } } } } } });
    var sel = S.sel ? search({ size: 1, query: { term: { key: S.sel.key } } }) : Promise.resolve(null);
    Promise.all([list, kpi, sel]).then(function (r) {
      S.err = null;
      S.items = r[0].hits.hits.map(function (h) { return h._source; });
      var c = {};
      r[1].aggregations.st.buckets.forEach(function (b) { c[b.key] = b.doc_count; });
      S.kpi = { c: c, silentHits: r[1].aggregations.hits.n.value || 0 };
      if (S.sel && r[2] && r[2].hits.hits.length) S.sel = r[2].hits.hits[0]._source;
    }).catch(function (e) { S.err = e.message; S.items = []; S.kpi = null; })
      .then(function () { S.busy = false; S.loadedAt = Date.now(); render(); });
  }

  function write(path, body, onOk) {
    S.writeErr = null; S.info = null;
    return fetch('/api/console/proxy?path=' + encodeURIComponent(path) + '&method=' + (/_doc\//.test(path) ? 'PUT' : 'POST'), {
      method: 'POST', credentials: 'same-origin',
      headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify(body)
    }).then(function (r) {
      if (!r.ok) throw new Error(r.status === 403 ? 'You do not have permission to manage AI rules.' : 'Update failed (HTTP ' + r.status + ').');
      if (onOk) onOk();
      S.loadedAt = 0; load();
      // El servicio trabaja en su siguiente pasada: se relee unas veces para mostrar el avance.
      [5000, 15000, 30000, 60000].forEach(function (ms) { setTimeout(function () { S.loadedAt = 0; load(); }, ms); });
    }).catch(function (e) { S.writeErr = e.message; render(); });
  }

  // Chat sobre la regla: se añade el mensaje con un script (no pisa lo que escriba la IA a la vez)
  // y el servicio responde en su siguiente pasada.
  function sendChat(doc, text) {
    var m = { role: 'user', by: S.user || 'analyst', at: new Date().toISOString(), text: text.slice(0, 2000) };
    var src = 'def s = ctx._source; if (s.chat == null) { s.chat = []; } s.chat.add(params.m); s.chat_pending = true; s.updated_at = params.m.at;';
    S.sel = Object.assign({}, doc, { chat: (doc.chat || []).concat([m]), chat_pending: true });
    S.stick = true; render();
    return write(INDEX + '/_update/' + encodeURIComponent(doc.key) + '?refresh=wait_for',
      { script: { lang: 'painless', source: src, params: { m: m } } });
  }

  function setStatus(doc, status, extra) {
    var d = Object.assign({ status: status, updated_at: new Date().toISOString() }, extra || {});
    return write(INDEX + '/_update/' + encodeURIComponent(doc.key) + '?refresh=wait_for', { doc: d });
  }

  function requestRule(text) {
    var key = 'req-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    var now = new Date().toISOString();
    return write(INDEX + '/_doc/' + key + '?op_type=create&refresh=wait_for', {
      kind: 'rule', key: key, status: 'requested', source: 'analyst', request: text.slice(0, 2000),
      requested_by: S.user || 'analyst', version: 0, created_at: now, updated_at: now
    }, function () { S.tab = 'work'; S.info = 'Request sent. The AI drafts it in the next minute; it will appear under "To review".'; });
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
  function st(s) { return '<span class="tsocInc__st tsocInc__st--' + esc(TONE[s] || 'closed') + '">' + esc(STATUS[s] || s) + '</span>'; }
  function lvl(n) {
    var sev = n >= 12 ? 'critical' : n >= 10 ? 'high' : n >= 7 ? 'medium' : 'low';
    return n ? '<span class="tsocInc__sev tsocInc__sev--' + sev + '">level ' + esc(n) + '</span>' : '<span class="tsocInc__muted">—</span>';
  }
  function empty(t, s) { return '<div class="tsocInc__empty"><b>' + esc(t) + '</b><span>' + esc(s) + '</span></div>'; }

  // ---------------------------------------------------------------- vista
  var root = null;
  function mount() {
    if (root) return root;
    root = document.createElement('div');
    root.id = 'tsoc-rules';
    root.className = 'tsocInc';
    root.addEventListener('click', onClick);
    root.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && S.sel) { S.sel = null; render(); return; }
      // Enter envía el mensaje del chat; Shift+Enter hace un salto de línea.
      if (e.key === 'Enter' && !e.shiftKey && e.target.matches('[data-chat]')) {
        e.preventDefault(); var send = root.querySelector('[data-act="send"]'); if (send) send.click();
      }
    });
    document.body.appendChild(root);
    S.loadedAt = 0; load();
    return root;
  }
  function unmount() { if (root) { root.remove(); root = null; S.sel = null; } }

  function kpis() {
    var k = S.kpi; if (!k) return '';
    var c = function (s) { return s.reduce(function (n, x) { return n + (k.c[x] || 0); }, 0); };
    return '<div class="tsocInc__kpis">' +
      card('To review', c(['proposed']), c(['invalid']) + ' failed validation', c(['proposed']) ? 'blue' : 'green') +
      card('Silent test', c(['silent']), k.silentHits + ' matches in 7 d, no notifications', 'purple') +
      card('Active rules', c(['active']), 'generated by AI, approved by a person', 'green') +
      card('In the AI queue', c(['requested', 'drafting', 'revision_requested']), c(['skipped']) + ' threats not detectable from logs', 'red') + '</div>';
  }
  function card(label, value, sub, color) {
    return '<div class="tsocInc__kpi tsocInc__kpi--' + color + '"><div class="tsocInc__kpiLabel">' + esc(label) + '</div>' +
      '<div class="tsocInc__kpiValue">' + esc(value) + '</div><div class="tsocInc__kpiSub">' + esc(sub) + '</div></div>';
  }

  function composer() {
    return '<div class="tsocInc__card tsocRul__ask"><b>Ask the AI for a new rule</b>' +
      '<span class="tsocInc__sub">Describe in plain words what should raise an alert. Example: "PowerShell launched by Word or Excel", ' +
      '"more than 10 failed SSH logins from the same IP in 2 minutes".</span>' +
      '<div class="tsocInc__note"><textarea data-ask rows="2" maxlength="2000" placeholder="What do you want to detect?"></textarea>' +
      '<button data-act="ask" class="tsocInc__btn tsocInc__btn--primary">Draft rule</button></div>' +
      (S.info ? '<div class="tsocInc__sub tsocRul__ok">' + esc(S.info) + '</div>' : '') +
      (S.writeErr && !S.sel ? '<div class="tsocInc__warn">' + esc(S.writeErr) + '</div>' : '') + '</div>';
  }

  function table() {
    if (S.err === 'NO_INDEX') return empty('The rule factory has not started yet.', 'Rules appear here once the TripleSOC Rulesmith service is running.');
    if (S.err) return empty('Rules could not be loaded.', S.err);
    if (!S.items.length) return empty(S.busy ? 'Loading…' : 'Nothing in this view.', S.tab === 'review' ? 'Ask the AI for a rule above, or wait for new threats from CISA KEV.' : '');
    var rows = S.items.map(function (d) {
      return '<tr data-open="' + esc(d.key) + '"' + (S.sel && S.sel.key === d.key ? ' class="is-sel"' : '') + '>' +
        '<td class="tsocInc__num">' + esc(d.rule_id || '—') + '</td>' +
        '<td><div class="tsocInc__title">' + esc(d.title || d.request) + '</div>' +
        '<div class="tsocInc__sub">' + esc(SOURCE[d.source] || d.source) + (d.source_ref ? ' · ' + esc(d.source_ref) : '') +
        (d.requested_by && d.source === 'analyst' ? ' · ' + esc(d.requested_by) : '') + '</div></td>' +
        '<td>' + lvl(d.level) + '</td>' +
        '<td>' + ((d.mitre || []).slice(0, 3).map(function (m) { return '<span class="tsocInc__chip">' + esc(m) + '</span>'; }).join('') || '<span class="tsocInc__muted">—</span>') + '</td>' +
        '<td class="tsocInc__num">' + (d.hits_7d != null ? esc(d.hits_7d) : '<span class="tsocInc__muted">—</span>') + '</td>' +
        '<td title="' + esc(when(d.updated_at)) + '">' + esc(ago(d.updated_at)) + '</td>' +
        '<td>' + st(d.status) + '</td></tr>';
    }).join('');
    return '<table class="tsocInc__table"><thead><tr><th class="tsocInc__num">Rule</th><th>Detection</th><th>Level</th><th>MITRE</th>' +
      '<th class="tsocInc__num">Hits 7 d</th><th>Updated</th><th>Status</th></tr></thead><tbody>' + rows + '</tbody></table>';
  }

  function actions(d) {
    var b = function (act, label, primary) { return '<button data-act="' + act + '" class="tsocInc__btn' + (primary ? ' tsocInc__btn--primary' : '') + '">' + label + '</button>'; };
    if (d.status === 'proposed') return '<div class="tsocInc__actions">' + b('approve', 'Approve · install in silent mode', true) + b('reject', 'Reject') + b('chat', 'Discuss with AI') + '</div>';
    if (d.status === 'invalid') return '<div class="tsocInc__actions">' + b('reject', 'Discard') + b('chat', 'Discuss with AI') + '</div>';
    if (d.status === 'silent') return '<div class="tsocInc__actions">' +
      (d.tests_passed ? b('promote', 'Promote to level ' + esc(d.level), true) : '') + b('disable', 'Disable') + '</div>' +
      (d.tests_passed ? '' : '<div class="tsocInc__sub">Promotion needs every logtest sample to pass. Discuss a fix with the AI or keep observing.</div>');
    if (d.status === 'active') return '<div class="tsocInc__actions">' + b('disable', 'Disable') + '</div>';
    if (d.status === 'install_failed') return '<div class="tsocInc__actions">' + b('approve', 'Retry install', true) + b('reject', 'Discard') + '</div>';
    return '';
  }

  // Conversación con la IA sobre esta regla (la responde el servicio triplesoc-rulesmith).
  function chatBox(d) {
    var who = { user: function (m) { return esc(m.by || 'analyst'); }, ai: function () { return 'AI'; }, system: function () { return 'TripleSOC'; } };
    var msgs = (d.chat || []).map(function (m) {
      var role = who[m.role] ? m.role : 'system';
      return '<li class="tsocRul__msg tsocRul__msg--' + role + '"><div class="tsocInc__sub">' + who[role](m) + ' · ' + esc(ago(m.at)) + '</div>' +
        '<div class="tsocRul__text">' + esc(m.text) + '</div>' +
        (m.change ? '<div class="tsocRul__change"><b>Agreed change:</b> ' + esc(m.change) + '</div>' : '') +
        (m.note ? '<div class="tsocInc__sub">' + esc(m.note) + '</div>' : '') + '</li>';
    }).join('');
    var waiting = d.chat_pending ? '<li class="tsocRul__msg tsocRul__msg--ai tsocRul__typing">AI is thinking…</li>' : '';
    return '<h3 id="tsoc-rules-chat">Chat with the AI</h3>' +
      '<div class="tsocInc__sub">Ask what this rule implies, what could trigger it, or how to improve it. ' +
      'Agreed changes become a new version that is validated again and needs your approval.</div>' +
      '<ul class="tsocRul__chat">' + (msgs || '<li class="tsocInc__muted">No messages yet. Try: "¿Qué implica activar esta regla?"</li>') + waiting + '</ul>' +
      '<div class="tsocInc__note"><textarea data-chat rows="2" maxlength="2000" placeholder="Write to the AI… (Enter sends, Shift+Enter new line)"></textarea>' +
      '<button data-act="send" class="tsocInc__btn tsocInc__btn--primary">Send</button></div>';
  }

  function drawer() {
    var d = S.sel; if (!d) return '';
    var checks = (d.checks || []).map(function (c) {
      return '<li class="tsocRul__check ' + (c.ok ? 'is-ok' : 'is-ko') + '"><b>' + (c.ok ? '✓ ' : '✗ ') + esc(c.name) + '</b> ' + esc(c.detail) + '</li>';
    }).join('');
    var n = d.noise || {};
    var tests = (d.tests || []).map(function (t) {
      return '<li class="tsocRul__check ' + (t.ok ? 'is-ok' : 'is-ko') + '"><b>' + (t.ok ? '✓' : '✗') + ' ' + (t.expect ? 'should fire' : 'should stay quiet') +
        '</b> · ' + (t.fired ? 'fired' : 'did not fire') + (t.matched_rule && !t.fired ? ' (matched rule ' + esc(t.matched_rule) + ')' : '') +
        '<code>' + esc(t.log) + '</code></li>';
    }).join('');
    var samples = !tests && d.spec && d.spec.tests && d.spec.tests.length
      ? '<ul class="tsocRul__checks">' + d.spec.tests.map(function (t) {
        return '<li class="tsocRul__check"><b>' + (t.expect ? 'should fire' : 'should stay quiet') + '</b><code>' + esc(t.log) + '</code></li>';
      }).join('') + '</ul><div class="tsocInc__sub">They run through wazuh-logtest once the rule is installed in silent mode.</div>' : '';
    var live = d.status === 'silent' || d.status === 'active';
    return '<aside class="tsocInc__drawer"><div class="tsocInc__dHead"><div>' + st(d.status) + ' ' + lvl(d.level) +
      '<h2>' + esc(d.title || d.request) + '</h2><div class="tsocInc__sub">' + (d.rule_id ? 'rule ' + esc(d.rule_id) + ' · ' : '') +
      esc(d.key) + (d.version ? ' · v' + esc(d.version) : '') + '</div></div>' +
      '<button data-act="close" class="tsocInc__x" aria-label="Close">×</button></div><div class="tsocInc__dBody">' +
      (d.error ? '<div class="tsocInc__warn">' + esc(d.error) + '</div>' : '') +
      (S.writeErr ? '<div class="tsocInc__warn">' + esc(S.writeErr) + '</div>' : '') +
      actions(d) +
      '<h3>Request</h3><div class="tsocInc__sub">' + esc(SOURCE[d.source] || d.source) + ' · ' + esc(d.requested_by || '') + ' · ' + esc(when(d.created_at)) + '</div>' +
      '<div class="tsocRul__text">' + esc(d.request) + '</div>' +
      (d.rationale ? '<h3>' + (d.status === 'skipped' ? 'Why no rule' : 'What it catches') + '</h3><div class="tsocRul__text">' + esc(d.rationale) + '</div>' : '') +
      (live || d.decided_by ? '<dl class="tsocInc__meta">' +
        '<div><dt>Approved by</dt><dd>' + esc(d.decided_by || '—') + '</dd></div>' +
        '<div><dt>Loaded at level</dt><dd>' + esc(d.installed_level || '—') + (d.status === 'silent' ? ' (silent)' : '') + '</dd></div>' +
        '<div><dt>Installed</dt><dd>' + esc(when(d.installed_at)) + '</dd></div>' +
        '<div><dt>Matches (7 d)</dt><dd>' + esc(d.hits_7d != null ? d.hits_7d : '—') + '</dd></div></dl>' : '') +
      (checks ? '<h3>Automatic validation</h3><ul class="tsocRul__checks">' + checks + '</ul>' : '') +
      (n.note ? '<h3>Expected noise (history, 30 d)</h3><div class="tsocRul__text">' +
        (n.parent_alerts_30d != null ? esc(n.similar_30d) + ' similar events · ' + esc(n.parent_alerts_30d) + ' from the parent rule. ' : '') + esc(n.note) + '</div>' : '') +
      (tests ? '<h3>wazuh-logtest</h3><ul class="tsocRul__checks">' + tests + '</ul>' : (samples ? '<h3>Test samples</h3>' + samples : '')) +
      (d.xml ? '<h3>Wazuh rule (generated)</h3><pre class="tsocRul__pre">' + esc(d.xml) + '</pre>' : '') +
      chatBox(d) +
      '<div class="tsocInc__sub tsocInc__recNote">The AI only fills a fixed template: ids, file and allowed XML elements are set by the service. ' +
      'Nothing is installed without approval, and every change is validated by Wazuh before it loads.</div>' +
      '</div></aside>';
  }

  function render() {
    if (!root) return;
    // El refresco periódico redibuja todo: se conservan el scroll del panel y lo que se esté escribiendo.
    var ask = root.querySelector('[data-ask]'), chat = root.querySelector('[data-chat]'), body = root.querySelector('.tsocInc__dBody');
    var focused = document.activeElement && document.activeElement.matches && document.activeElement.matches('[data-chat]');
    var keep = { ask: ask ? ask.value : '', chat: chat ? chat.value : '', top: body ? body.scrollTop : 0, key: S.sel && S.sel.key };
    var tabs = TABS.map(function (t) { return '<button data-tab="' + t.id + '" class="' + (S.tab === t.id ? 'is-on' : '') + '">' + esc(t.label) + '</button>'; }).join('');
    root.innerHTML = '<div class="tsocInc__page">' +
      '<div class="tsocInc__head"><div><h1>AI Rules</h1><p>Detection rules drafted by AI from analyst requests and new threats · validated automatically · installed only with your approval</p></div>' +
      '<button data-act="refresh" class="tsocInc__btn">' + (S.busy ? 'Refreshing…' : 'Refresh') + '</button></div>' +
      kpis() + composer() +
      '<div class="tsocInc__bar"><div class="tsocInc__tabs">' + tabs + '</div></div>' +
      '<div class="tsocInc__card">' + table() + '</div></div>' + drawer();
    root.classList.toggle('has-drawer', !!S.sel);
    if (keep.ask) root.querySelector('[data-ask]').value = keep.ask;
    var c = root.querySelector('[data-chat]'), b2 = root.querySelector('.tsocInc__dBody');
    if (c && keep.chat && keep.key === (S.sel && S.sel.key)) c.value = keep.chat;
    if (b2) {
      // Tras enviar un mensaje (o al llegar la respuesta) se baja al final del chat; si no, se queda donde estaba.
      var n = (S.sel && S.sel.chat || []).length;
      if (S.stick || (keep.key === S.sel.key && n !== S.chatLen && S.chatLen != null)) b2.scrollTop = b2.scrollHeight;
      else if (keep.key === S.sel.key) b2.scrollTop = keep.top;
      S.stick = false; S.chatLen = n;
    } else { S.chatLen = null; }
    if (c && focused) c.focus();
  }

  function onClick(e) {
    var t = e.target.closest('[data-tab],[data-open],[data-act]');
    if (!t) return;
    if (t.hasAttribute('data-tab')) { S.tab = t.getAttribute('data-tab'); S.sel = null; S.loadedAt = 0; load(); return; }
    if (t.hasAttribute('data-open')) {
      var key = t.getAttribute('data-open');
      S.sel = S.items.filter(function (d) { return d.key === key; })[0] || null; S.writeErr = null; render(); return;
    }
    var act = t.getAttribute('data-act'), d = S.sel, user = me() || 'analyst';
    if (act === 'refresh') { S.loadedAt = 0; load(); return; }
    if (act === 'close') { S.sel = null; render(); return; }
    if (act === 'ask') {
      var ta = root.querySelector('[data-ask]'), text = ta && ta.value.trim();
      if (text && text.length >= 10) { ta.value = ''; requestRule(text); } else { S.writeErr = 'Describe the detection in a few more words.'; render(); }
      return;
    }
    if (!d) return;
    var now = new Date().toISOString();
    if (act === 'approve') {
      if (window.confirm('Install rule ' + d.rule_id + ' in silent mode?\nThe Wazuh manager restarts (about 1 minute). The rule logs matches but sends no notifications until you promote it.'))
        setStatus(d, 'approved', { decided_by: user, decided_at: now });
    }
    if (act === 'reject') setStatus(d, 'rejected', { decided_by: user, decided_at: now });
    if (act === 'promote' && window.confirm('Promote rule ' + d.rule_id + ' to level ' + d.level + '?' + (d.level >= 12 ? '\nLevel 12 alerts notify Teams and the webhook.' : '') + '\nThe Wazuh manager restarts.'))
      setStatus(d, 'promote_requested', { promoted_by: user });
    if (act === 'disable' && window.confirm('Disable rule ' + d.rule_id + '? The Wazuh manager restarts.'))
      setStatus(d, 'disable_requested', { disabled_by: user });
    if (act === 'chat') {
      var cb = root.querySelector('[data-chat]'), body = root.querySelector('.tsocInc__dBody');
      if (body) body.scrollTop = body.scrollHeight;
      if (cb) cb.focus();
    }
    if (act === 'send') {
      var ta2 = root.querySelector('[data-chat]'), msg = ta2 && ta2.value.trim();
      if (!msg) return;
      ta2.value = ''; sendChat(d, msg);
    }
  }

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
      if (!root.isConnected) document.body.appendChild(root);
      place();
      // render() conserva lo escrito, así que se puede refrescar siempre; más a menudo mientras la IA trabaja.
      var working = S.sel && (S.sel.chat_pending || /^(requested|drafting|revision_requested|approved|promote_requested|disable_requested)$/.test(S.sel.status));
      if (!S.busy && Date.now() - S.loadedAt > (working ? 3000 : 20000)) load();
    } catch (err) { /* nunca romper la página */ }
  }
  setInterval(tick, 500);
})();
/* ==== fin TripleSOC rules ==== */
