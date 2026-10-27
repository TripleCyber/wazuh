/* ==== TripleSOC endpoints ====
   Pantallas propias que sustituyen a las del plugin de Wazuh del dashboard (GPL-2.0), que ya no va en la imagen:
     Entities    (/app/dashboards#/view/triplesoc-entities)  equipos protegidos y su estado
     Trust Zones (/app/dashboards#/view/triplesoc-zones)     grupos de equipos
     Attack Map  (/app/dashboards#/view/triplesoc-attack)    técnicas y tácticas MITRE ATT&CK vistas en las alertas
     APIs        (/app/dashboards#/view/triplesoc-platform)  conexión con el manager y frescura de los datos
   Como Incidents: se dibujan sobre un tablero guardado vacío que sirve de ruta y leen el indexer con los permisos
   del usuario (/internal/search/opensearch). Los equipos los copia triplesoc-responder desde la API de Wazuh al
   índice triplesoc-incidents-agents cada 5 min. apply-branding.sh lo AÑADE al final de core.entry.js. */
;(function () {
  'use strict';
  var TS = window.TSOC_SCHEMA; // capa traductora (triplesoc-schema.js): índice y campos de alertas
  if (!TS) return;
  if (window.__tsocEndpoints) return;
  window.__tsocEndpoints = true;

  var AGENTS = 'triplesoc-incidents-agents';
  var GUARDIAN = 'triplesoc-incidents-guardian';
  var INCIDENTS = 'triplesoc-incidents';
  var MITRE = TS.f.rule_mitre; // rule.mitre → .id, .tactic, .technique
  var PAGES = {
    entities: { id: 'triplesoc-entities', title: 'TripleSOC · Entities', desc: 'Protected endpoints and their status' },
    zones: { id: 'triplesoc-zones', title: 'TripleSOC · Trust Zones', desc: 'Endpoint groups' },
    attack: { id: 'triplesoc-attack', title: 'TripleSOC · Attack Map', desc: 'MITRE ATT&CK techniques seen in alerts' },
    platform: { id: 'triplesoc-platform', title: 'TripleSOC · APIs', desc: 'Connection with the Wazuh manager and data freshness' }
  };
  var TACTICS = ['Reconnaissance', 'Resource Development', 'Initial Access', 'Execution', 'Persistence', 'Privilege Escalation',
    'Defense Evasion', 'Credential Access', 'Discovery', 'Lateral Movement', 'Collection', 'Command and Control', 'Exfiltration', 'Impact'];
  var STATUS = { active: 'Active', disconnected: 'Disconnected', pending: 'Pending', never_connected: 'Never connected' };
  var RANGES = [{ id: '24h', label: 'Last 24 h' }, { id: '7d', label: 'Last 7 days' }, { id: '30d', label: 'Last 30 days' }];
  var S = { page: null, data: null, err: null, busy: false, loadedAt: 0, tab: 'all', q: '', range: '7d', sel: null };

  // ---------------------------------------------------------------- datos
  function search(index, body) {
    return fetch('/internal/search/opensearch', {
      method: 'POST', credentials: 'same-origin',
      headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify({ params: { index: index, body: body } })
    }).then(function (r) {
      if (!r.ok) return r.json().catch(function () { return {}; }).then(function (j) {
        var msg = JSON.stringify(j); throw new Error(/index_not_found/.test(msg) ? 'NO_INDEX' : 'HTTP ' + r.status);
      });
      return r.json();
    }).then(function (j) { return j.rawResponse; });
  }
  function quiet(p) { return p.catch(function () { return null; }); }

  function loadAgents() {
    return Promise.all([
      search(AGENTS, { size: 2000, query: { bool: { filter: [{ term: { kind: 'agent' } }], must_not: [{ term: { id: '000' } }] } }, sort: [{ name: 'asc' }] }),
      quiet(search(AGENTS, { size: 1, query: { term: { kind: 'platform' } } }))
    ]).then(function (r) {
      return { agents: r[0].hits.hits.map(function (h) { return h._source; }), platform: plat(r[1]) };
    });
  }
  function plat(r) { return r && r.hits.hits.length ? r.hits.hits[0]._source : null; }

  function loadAttack() {
    var f = { bool: { filter: [{ range: {} }, { exists: { field: MITRE + '.id' } }] } };
    f.bool.filter[0].range[TS.f.timestamp] = { gte: 'now-' + S.range };
    return search(TS.idx.alerts, { size: 0, track_total_hits: true, query: f, aggs: {
      tactics: { terms: { field: MITRE + '.tactic', size: 30 } },
      agents: { cardinality: { field: TS.f.agent_id } },
      techniques: { terms: { field: MITRE + '.id', size: 100 }, aggs: {
        name: { terms: { field: MITRE + '.technique', size: 1 } },
        tactic: { terms: { field: MITRE + '.tactic', size: 5 } },
        agents: { cardinality: { field: TS.f.agent_id } },
        last: { max: { field: TS.f.timestamp } } } }
    } }).then(function (r) {
      var a = r.aggregations;
      return {
        total: typeof r.hits.total === 'number' ? r.hits.total : r.hits.total.value,
        agents: a.agents.value,
        tactics: a.tactics.buckets.reduce(function (o, b) { o[b.key] = b.doc_count; return o; }, {}),
        techniques: a.techniques.buckets.map(function (b) {
          return { id: b.key, count: b.doc_count, name: b.name.buckets.length ? b.name.buckets[0].key : b.key,
            tactics: b.tactic.buckets.map(function (t) { return t.key; }), agents: b.agents.value, last: b.last.value_as_string || b.last.value };
        })
      };
    });
  }

  function loadPlatform() {
    var last = function (index, field, q) {
      var s = {}; s[field] = 'desc';
      return quiet(search(index, { size: 1, _source: [field], sort: [s], query: q || { match_all: {} } })).then(function (r) {
        var h = r && r.hits.hits[0]; if (!h) return null;
        return field.split('.').reduce(function (o, k) { return o && o[k]; }, h._source);
      });
    };
    return Promise.all([
      quiet(search(AGENTS, { size: 1, query: { term: { kind: 'platform' } } })),
      last(TS.idx.alerts, TS.f.timestamp),
      last(INCIDENTS, 'updated_at'),
      quiet(search(GUARDIAN, { size: 1, query: { term: { kind: 'pulse' } } })),
      quiet(search(AGENTS, { size: 0, query: { term: { kind: 'agent' } }, aggs: { st: { terms: { field: 'status', size: 10 } } } }))
    ]).then(function (r) {
      var pulse = r[3] && r[3].hits.hits[0] && r[3].hits.hits[0]._source;
      var st = {}; (r[4] && r[4].aggregations ? r[4].aggregations.st.buckets : []).forEach(function (b) { st[b.key] = b.doc_count; });
      return { platform: plat(r[0]), lastAlert: r[1], lastIncident: r[2], pulse: pulse, status: st };
    });
  }

  function load() {
    if (S.busy || !S.page) return;
    S.busy = true;
    var page = S.page;
    var p = page === 'attack' ? loadAttack() : page === 'platform' ? loadPlatform() : loadAgents();
    p.then(function (d) { if (S.page === page) { S.data = d; S.err = null; } })
      .catch(function (e) { if (S.page === page) { S.err = e.message; S.data = null; } })
      .then(function () { S.busy = false; S.loadedAt = Date.now(); render(); });
  }

  // Los tableros vacíos que sirven de ruta se crean la primera vez (si el usuario puede guardar objetos).
  var ensured = false;
  function ensureRoutes() {
    if (ensured) return; ensured = true;
    var h = { 'osd-xsrf': 'true', 'content-type': 'application/json' };
    var ids = Object.keys(PAGES).map(function (k) { return { type: 'dashboard', id: PAGES[k].id }; });
    fetch('/api/saved_objects/_bulk_get', { method: 'POST', credentials: 'same-origin', headers: h, body: JSON.stringify(ids) })
      .then(function (r) { return r.ok ? r.json() : null; }).then(function (j) {
        if (!j) return;
        j.saved_objects.forEach(function (o) {
          if (!o.error || o.error.statusCode !== 404) return;
          var pg = Object.keys(PAGES).map(function (k) { return PAGES[k]; }).filter(function (p) { return p.id === o.id; })[0];
          fetch('/api/saved_objects/dashboard/' + pg.id, { method: 'POST', credentials: 'same-origin', headers: h, body: JSON.stringify({ attributes: {
            title: pg.title, description: pg.desc, panelsJSON: '[]', optionsJSON: '{"useMargins":true,"hidePanelTitles":false}',
            version: 1, timeRestore: false, kibanaSavedObjectMeta: { searchSourceJSON: '{"query":{"query":"","language":"kuery"},"filter":[]}' }
          } }) }).catch(function () {});
        });
      }).catch(function () {});
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
  function num(n) { return Number(n || 0).toLocaleString(); }
  function card(label, value, sub, color) {
    return '<div class="tsocInc__kpi tsocInc__kpi--' + color + '"><div class="tsocInc__kpiLabel">' + esc(label) + '</div>' +
      '<div class="tsocInc__kpiValue">' + esc(value) + '</div><div class="tsocInc__kpiSub">' + esc(sub) + '</div></div>';
  }
  function empty(t, s) { return '<div class="tsocInc__empty"><b>' + esc(t) + '</b><span>' + esc(s || '') + '</span></div>'; }
  function chip(t) { return '<span class="tsocInc__chip">' + esc(t) + '</span>'; }
  function status(s) { return '<span class="tsocEp__st tsocEp__st--' + esc(s) + '">' + esc(STATUS[s] || s || '—') + '</span>'; }
  function discover(q, from) {
    return "/app/data-explorer/discover#?_a=(discover:(columns:!(" + TS.columns.join(',') + "),isDirty:!f,sort:!())," +
      "metadata:(indexPattern:'" + TS.idx.alerts + "',view:discover))&_g=(filters:!(),refreshInterval:(pause:!t,value:0)," +
      "time:(from:now-" + (from || '24h') + ",to:now))&_q=(filters:!(),query:(language:kuery,query:'" + q.replace(/'/g, "!'") + "'))";
  }
  function agentAlerts(a) { return discover(TS.f.agent_id + ':"' + a.id + '"', '7d'); }
  function fresh(p) {
    if (!p) return 'Endpoint inventory not received yet (TripleSOC Responder copies it every 5 min).';
    return 'Inventory updated ' + ago(p.updated_at) + (p.api === 'error' ? ' · last attempt failed: ' + p.error : '');
  }
  function head(title, sub) {
    return '<div class="tsocInc__head"><div><h1>' + esc(title) + '</h1><p>' + esc(sub) + '</p></div>' +
      '<button data-act="refresh" class="tsocInc__btn">' + (S.busy ? 'Refreshing…' : 'Refresh') + '</button></div>';
  }
  function failed(what) {
    if (S.err === 'NO_INDEX') return empty('No ' + what + ' yet.', 'The TripleSOC Responder creates this data within 5 minutes of starting.');
    return empty(what.charAt(0).toUpperCase() + what.slice(1) + ' could not be loaded.', S.err);
  }

  // ---------------------------------------------------------------- vistas
  function counts(list) {
    var c = { total: list.length, active: 0, disconnected: 0, pending: 0 };
    list.forEach(function (a) { if (a.status === 'active') c.active++; else if (a.status === 'disconnected') c.disconnected++; else c.pending++; });
    return c;
  }

  function viewEntities() {
    var d = S.data;
    var out = head('Entities', 'Protected endpoints, their agent and when they last reported');
    if (S.err) return out + '<div class="tsocInc__card">' + failed('endpoints') + '</div>';
    if (!d) return out + '<div class="tsocInc__card">' + empty('Loading…') + '</div>';
    var c = counts(d.agents);
    out += '<div class="tsocInc__kpis">' + card('Endpoints', num(c.total), 'with a TripleSOC agent', 'blue') +
      card('Active', num(c.active), 'reporting now', 'green') + card('Disconnected', num(c.disconnected), 'not reporting', c.disconnected ? 'red' : 'green') +
      card('Pending', num(c.pending), 'registered, never connected', 'purple') + '</div>';
    var tabs = [['all', 'All'], ['active', 'Active'], ['disconnected', 'Disconnected'], ['pending', 'Pending']].map(function (t) {
      return '<button data-tab="' + t[0] + '" class="' + (S.tab === t[0] ? 'is-on' : '') + '">' + t[1] + '</button>';
    }).join('');
    var q = S.q.toLowerCase();
    var rows = d.agents.filter(function (a) {
      if (S.tab === 'active' && a.status !== 'active') return false;
      if (S.tab === 'disconnected' && a.status !== 'disconnected') return false;
      if (S.tab === 'pending' && (a.status === 'active' || a.status === 'disconnected')) return false;
      return !q || [a.name, a.id, a.ip, a.os_name, (a.groups || []).join(' ')].join(' ').toLowerCase().indexOf(q) >= 0;
    });
    var body = rows.length ? '<table class="tsocInc__table"><thead><tr><th>Status</th><th>Endpoint</th><th>IP</th><th>Operating system</th>' +
      '<th>Trust zones</th><th>Agent</th><th>Last report</th><th></th></tr></thead><tbody>' + rows.map(function (a) {
        return '<tr><td>' + status(a.status) + '</td>' +
          '<td><div class="tsocInc__title">' + esc(a.name) + '</div><div class="tsocInc__sub">ID ' + esc(a.id) + '</div></td>' +
          '<td>' + esc(a.ip || '—') + '</td>' +
          '<td>' + esc([a.os_name, a.os_version].filter(Boolean).join(' ') || '—') + '</td>' +
          '<td>' + ((a.groups || []).map(chip).join('') || '<span class="tsocInc__muted">—</span>') + '</td>' +
          '<td>' + esc((a.version || '—').replace(/^Wazuh /, '')) + '</td>' +
          '<td title="' + esc(when(a.last_keepalive)) + '">' + esc(ago(a.last_keepalive)) + '</td>' +
          '<td><a class="tsocInc__btn tsocInc__btn--ghost" data-nav href="' + esc(agentAlerts(a)) + '">Alerts</a></td></tr>';
      }).join('') + '</tbody></table>'
      : empty(d.agents.length ? 'No endpoints in this view.' : 'No endpoints registered yet.', S.q ? 'Try another search.' : '');
    return out + '<div class="tsocInc__bar"><div class="tsocInc__tabs">' + tabs + '</div>' +
      '<input data-search type="search" placeholder="Search name, IP, system or zone" value="' + esc(S.q) + '"></div>' +
      '<div class="tsocInc__card">' + body + '</div><div class="tsocInc__sub tsocEp__foot">' + esc(fresh(d.platform)) + '</div>';
  }

  function viewZones() {
    var d = S.data;
    var out = head('Trust Zones', 'Endpoint groups: each one receives the monitoring policy of its zone');
    if (S.err) return out + '<div class="tsocInc__card">' + failed('zones') + '</div>';
    if (!d) return out + '<div class="tsocInc__card">' + empty('Loading…') + '</div>';
    var zones = {};
    d.agents.forEach(function (a) {
      (a.groups && a.groups.length ? a.groups : ['(no zone)']).forEach(function (g) { (zones[g] = zones[g] || []).push(a); });
    });
    var names = Object.keys(zones).sort(function (x, y) { return zones[y].length - zones[x].length || x.localeCompare(y); });
    if (!names.length) return out + '<div class="tsocInc__card">' + empty('No endpoints registered yet.', fresh(d.platform)) + '</div>';
    return out + '<div class="tsocEp__zones">' + names.map(function (g) {
      var list = zones[g], c = counts(list);
      return '<div class="tsocInc__card tsocEp__zone"><div class="tsocEp__zoneHead"><h2>' + esc(g) + '</h2>' +
        '<span class="tsocInc__sub">' + num(c.total) + ' endpoint' + (c.total === 1 ? '' : 's') + '</span></div>' +
        '<div class="tsocEp__zoneStats">' + status('active') + ' ' + num(c.active) + ' &nbsp; ' + status('disconnected') + ' ' + num(c.disconnected) +
        (c.pending ? ' &nbsp; ' + status('pending') + ' ' + num(c.pending) : '') + '</div>' +
        '<ul class="tsocEp__members">' + list.slice(0, 12).map(function (a) {
          return '<li><a data-nav href="' + esc(agentAlerts(a)) + '">' + esc(a.name) + '</a> <span class="tsocInc__sub">' + esc(a.ip || '') + '</span></li>';
        }).join('') + (list.length > 12 ? '<li class="tsocInc__muted">+' + (list.length - 12) + ' more</li>' : '') + '</ul></div>';
    }).join('') + '</div><div class="tsocInc__sub tsocEp__foot">' + esc(fresh(d.platform)) + '</div>';
  }

  function viewAttack() {
    var d = S.data;
    var ranges = RANGES.map(function (r) { return '<button data-range="' + r.id + '" class="' + (S.range === r.id ? 'is-on' : '') + '">' + r.label + '</button>'; }).join('');
    var out = head('Attack Map', 'MITRE ATT&CK techniques detected in the alerts, by phase of the attack') +
      '<div class="tsocInc__bar"><div class="tsocInc__tabs">' + ranges + '</div></div>';
    if (S.err) return out + '<div class="tsocInc__card">' + failed('attack data') + '</div>';
    if (!d) return out + '<div class="tsocInc__card">' + empty('Loading…') + '</div>';
    var known = TACTICS.concat(Object.keys(d.tactics).filter(function (t) { return TACTICS.indexOf(t) < 0; }));
    var max = Math.max.apply(null, [1].concat(known.map(function (t) { return d.tactics[t] || 0; })));
    out += '<div class="tsocInc__kpis">' + card('Alerts with MITRE mapping', num(d.total), RANGES.filter(function (r) { return r.id === S.range; })[0].label, 'red') +
      card('Techniques', num(d.techniques.length), 'distinct ATT&CK techniques', 'purple') +
      card('Tactics', num(Object.keys(d.tactics).length), 'of ' + TACTICS.length + ' attack phases', 'blue') +
      card('Endpoints', num(d.agents), 'with at least one of these alerts', 'green') + '</div>';
    out += '<div class="tsocInc__card"><h3 class="tsocEp__h3">Attack phases</h3><div class="tsocEp__tactics">' + known.map(function (t) {
      var n = d.tactics[t] || 0;
      return '<div class="tsocEp__tactic' + (n ? ' is-on' : '') + '" title="' + esc(t) + ': ' + num(n) + ' alerts"><div class="tsocEp__bar"><i style="height:' +
        (n ? Math.max(6, Math.round(n / max * 100)) : 0) + '%"></i></div><b>' + num(n) + '</b><span>' + esc(t) + '</span></div>';
    }).join('') + '</div></div>';
    var rows = d.techniques.map(function (t) {
      return '<tr><td><b>' + esc(t.id) + '</b></td><td>' + esc(t.name) + '</td><td>' + t.tactics.map(chip).join('') + '</td>' +
        '<td class="tsocInc__num">' + num(t.count) + '</td><td class="tsocInc__num">' + num(t.agents) + '</td>' +
        '<td title="' + esc(when(t.last)) + '">' + esc(ago(t.last)) + '</td>' +
        '<td><a class="tsocInc__btn tsocInc__btn--ghost" data-nav href="' + esc(discover(MITRE + '.id:"' + t.id + '"', S.range)) + '">Alerts</a></td></tr>';
    }).join('');
    return out + '<div class="tsocInc__card">' + (rows ? '<table class="tsocInc__table"><thead><tr><th>ID</th><th>Technique</th><th>Tactics</th>' +
      '<th class="tsocInc__num">Alerts</th><th class="tsocInc__num">Endpoints</th><th>Last seen</th><th></th></tr></thead><tbody>' + rows + '</tbody></table>'
      : empty('No MITRE techniques in this period.', 'Alerts whose rule maps to ATT&CK appear here.')) + '</div>';
  }

  function viewPlatform() {
    var d = S.data;
    var out = head('APIs', 'Connection between TripleSOC and the Wazuh manager, and how fresh each data source is');
    if (S.err) return out + '<div class="tsocInc__card">' + failed('platform status') + '</div>';
    if (!d) return out + '<div class="tsocInc__card">' + empty('Loading…') + '</div>';
    var p = d.platform;
    var stale = function (iso, min) { return !iso || Date.now() - Date.parse(iso) > min * 60000; };
    var apiOk = p && p.api === 'ok' && !stale(p.updated_at, 15);
    out += '<div class="tsocInc__kpis">' +
      card('Wazuh manager API', !p ? 'Unknown' : apiOk ? 'Connected' : 'Error', p ? 'checked ' + ago(p.updated_at) + (p.api_ms ? ' · ' + p.api_ms + ' ms' : '') : 'no check yet', apiOk ? 'green' : 'red') +
      card('Manager version', p && p.manager_version ? p.manager_version.replace(/^Wazuh /, '') : '—', 'detection engine', 'blue') +
      card('Endpoints', num(p ? Math.max(0, (p.agents_total || 0) - 1) : 0), num(d.status.active ? d.status.active - 1 : 0) + ' active', 'purple') +
      card('Last alert received', ago(d.lastAlert), when(d.lastAlert), stale(d.lastAlert, 60) ? 'red' : 'green') + '</div>';
    var row = function (name, what, iso, maxMin, extra) {
      var ok = !stale(iso, maxMin);
      return '<tr><td>' + '<span class="tsocEp__st tsocEp__st--' + (ok ? 'active' : 'disconnected') + '">' + (ok ? 'OK' : 'Check') + '</span>' + '</td><td><div class="tsocInc__title">' + esc(name) +
        '</div><div class="tsocInc__sub">' + esc(what) + '</div></td><td title="' + esc(when(iso)) + '">' + esc(ago(iso)) + '</td><td>' + esc(extra || '') + '</td></tr>';
    };
    var pulse = d.pulse || {};
    return out + '<div class="tsocInc__card"><table class="tsocInc__table"><thead><tr><th>State</th><th>Component</th><th>Last activity</th><th>Detail</th></tr></thead><tbody>' +
      row('Manager → indexer', 'alerts written to ' + TS.idx.alerts, d.lastAlert, 60) +
      row('Wazuh API → inventory', 'endpoints copied by TripleSOC Responder every 5 min', p && p.api === 'ok' ? p.updated_at : null, 15, p && p.api === 'error' ? p.error : '') +
      row('TripleSOC Responder', 'responses, Guardian and the fast lane', pulse.at, 2, pulse.mode ? 'mode ' + pulse.mode : '') +
      row('TripleSOC Incidents', 'alert correlation into incidents', d.lastIncident, 24 * 60) +
      '</tbody></table></div>';
  }

  // ---------------------------------------------------------------- montaje (igual que Incidents)
  var root = null;
  function mount() {
    if (root) return root;
    root = document.createElement('div');
    root.id = 'tsoc-ep';
    root.className = 'tsocInc tsocEp';
    root.addEventListener('click', onClick);
    root.addEventListener('input', function (e) {
      if (e.target.matches('[data-search]')) { S.q = e.target.value.trim(); render(); }
    });
    document.body.appendChild(root);
    return root;
  }
  function unmount() { if (root) { root.remove(); root = null; } }

  function render() {
    if (!root) return;
    var focus = document.activeElement && document.activeElement.matches && document.activeElement.matches('[data-search]');
    var v = { entities: viewEntities, zones: viewZones, attack: viewAttack, platform: viewPlatform }[S.page];
    root.innerHTML = '<div class="tsocInc__page">' + (v ? v() : '') + '</div>';
    if (focus) { var s = root.querySelector('[data-search]'); if (s) { s.focus(); s.setSelectionRange(s.value.length, s.value.length); } }
  }

  function onClick(e) {
    var t = e.target.closest('[data-tab],[data-range],[data-act],[data-nav]');
    if (!t) return;
    if (t.hasAttribute('data-nav')) {
      if (e.button !== 0 || e.ctrlKey || e.metaKey || e.shiftKey) return;
      e.preventDefault(); history.pushState(null, '', t.getAttribute('href')); window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
      return;
    }
    if (t.hasAttribute('data-tab')) { S.tab = t.getAttribute('data-tab'); render(); return; }
    if (t.hasAttribute('data-range')) { S.range = t.getAttribute('data-range'); S.data = null; render(); load(); return; }
    if (t.getAttribute('data-act') === 'refresh') load();
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

  function current() {
    var here = location.pathname + decodeURIComponent(location.hash);
    if (!/^\/app\/dashboards/.test(here)) return null;
    for (var k in PAGES) if (here.indexOf('view/' + PAGES[k].id) >= 0) return k;
    return null;
  }

  function tick() {
    try {
      if (/^\/app\//.test(location.pathname) && !/^\/app\/login/.test(location.pathname)) ensureRoutes();
      var page = current();
      if (!page) { unmount(); S.page = null; return; }
      mount();
      if (!root.isConnected) document.body.appendChild(root);
      place();
      if (page !== S.page) { S.page = page; S.data = null; S.err = null; S.q = ''; S.tab = 'all'; render(); load(); return; }
      if (!S.busy && Date.now() - S.loadedAt > 60000) load();
    } catch (err) { /* nunca romper la página */ }
  }
  setInterval(tick, 500);
})();
/* ==== fin TripleSOC endpoints ==== */
