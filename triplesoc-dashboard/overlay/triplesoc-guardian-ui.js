/* ==== TripleSOC guardian ====
   Pantalla "Guardian": el robot que resume en lenguaje sencillo lo que detectó y lo que hizo el servicio
   triplesoc-responder, con el interruptor Automático / Manual con aprobación.
   Se muestra sobre el tablero guardado "triplesoc-guardian" (ruta /app/dashboards#/view/triplesoc-guardian).
   apply-branding.sh lo AÑADE al final de core.entry.js: no modifica código existente.
   El interruptor solo escribe un documento (índice triplesoc-incidents-guardian) con la sesión del usuario;
   quien actúa es el servicio, que además necesita MODE=approve en su configuración. */
;(function () {
  'use strict';
  if (window.__tsocGuardian) return;
  window.__tsocGuardian = true;

  var ROUTE = /^\/app\/dashboards.*view\/triplesoc-guardian/;
  var IDX = { resp: 'triplesoc-incidents-responses', inc: 'triplesoc-incidents', set: 'triplesoc-incidents-guardian',
    rules: 'triplesoc-incidents-rules', alerts: 'triplesoc-alerts-*' };
  var S = { mode: null, changed: null, stories: [], k: null, state: 'watching', busy: false, loadedAt: 0, err: null, user: null, live: null, traces: [], pulse: null, peekAt: 0, liveKey: null, replay: null };

  function search(index, body) {
    return fetch('/internal/search/opensearch', {
      method: 'POST', credentials: 'same-origin', headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify({ params: { index: index, body: body } })
    }).then(function (r) { return r.ok ? r.json().then(function (j) { return j.rawResponse; }) : null; })
      .catch(function () { return null; });
  }
  function proxy(path, method, body) {
    return fetch('/api/console/proxy?path=' + encodeURIComponent(path) + '&method=' + method, {
      method: 'POST', credentials: 'same-origin', headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify(body)
    });
  }
  function total(h) { return h ? (typeof h.total === 'number' ? h.total : (h.total && h.total.value) || 0) : 0; }

  function load() {
    if (S.busy) return;
    S.busy = true;
    var day = new Date(); day.setHours(0, 0, 0, 0);
    Promise.all([
      search(IDX.set, { size: 1, query: { ids: { values: ['settings'] } } }),
      search(IDX.resp, { size: 25, sort: [{ story_at: { order: 'desc', unmapped_type: 'date' } }], query: { exists: { field: 'story' } } }),
      search(IDX.resp, { size: 0, query: { range: { story_at: { gte: 'now-7d' } } }, aggs: {
        today: { filter: { range: { story_at: { gte: day.toISOString() } } }, aggs: { st: { filter: { terms: { story_outcome: ['executed', 'contained'] } } } } },
        week: { filter: { terms: { story_outcome: ['executed', 'contained'] } } },
        auto: { filter: { term: { auto: true } } },
        speed: { filter: { term: { story_outcome: 'executed' } }, aggs: { s: { avg: { field: 'response_seconds' } } } } } }),
      // Incidentes altos/críticos de 7 días y cuántos tienen ya una respuesta aplicada (para el escudo).
      search(IDX.inc, { size: 200, _source: ['incident_id', 'status', 'last_seen'], query: { bool: { filter: [
        { range: { severity_rank: { gte: 3 } } }, { range: { first_seen: { gte: 'now-7d' } } }] } } }),
      search(IDX.resp, { size: 200, _source: ['incident_id', 'status', 'story_outcome'], query: { range: { updated_at: { gte: 'now-8d' } } } }),
      search(IDX.rules, { size: 0, query: { bool: { filter: [{ term: { kind: 'rule' } }, { terms: { status: ['silent', 'active'] } }] } } }),
      search(IDX.alerts, { size: 0, query: { range: { timestamp: { gte: 'now-24h' } } }, aggs: { a: { cardinality: { field: 'agent.id' } } } }),
      search(IDX.resp, { size: 5, _source: ['incident_id', 'status', 'title', 'agent', 'action_label', 'undo_by'], query: { terms: { status: ['approved', 'executing', 'undo_requested', 'undoing'] } } })
    ]).then(function (r) {
      var set = r[0] && r[0].hits.hits[0] && r[0].hits.hits[0]._source;
      S.mode = set && set.mode === 'auto' ? 'auto' : 'manual';
      S.changed = set ? set : null;
      S.stories = r[1] ? r[1].hits.hits.map(function (h) { return h._source; }) : [];
      var a = r[2] && r[2].aggregations;
      var incs = r[3] ? r[3].hits.hits.map(function (h) { return h._source; }) : [];
      var resp = {}; (r[4] ? r[4].hits.hits : []).forEach(function (h) { resp[h._source.incident_id] = h._source; });
      var handled = incs.filter(function (i) {
        var x = resp[i.incident_id];
        return i.status === 'resolved' || i.status === 'false_positive' || (x && /^(executed|executing|undone)$/.test(x.status)) ||
          (x && x.story_outcome === 'contained');
      }).length;
      var open = incs.filter(function (i) {
        var x = resp[i.incident_id];
        return (i.status === 'new' || i.status === 'investigating') && !(x && /^(executed|executing)$/.test(x.status)) &&
          !(x && x.story_outcome === 'contained') && Date.now() - Date.parse(i.last_seen) < 15 * 60000;
      }).length;
      S.k = {
        today: a ? a.today.st.doc_count : 0, week: a ? a.week.doc_count : 0, auto: a ? a.auto.doc_count : 0,
        speed: a && a.speed.s.value != null ? Math.round(a.speed.s.value) : null,
        shield: incs.length ? Math.round(handled / incs.length * 100) : 100, attacks: incs.length,
        rules: total(r[5] && r[5].hits), endpoints: r[6] && r[6].aggregations ? r[6].aggregations.a.value : 0
      };
      S.live = r[7] && r[7].hits.hits.length ? r[7].hits.hits[0]._source : null;
      S.state = S.live ? (/^undo/.test(S.live.status) ? 'undoing' : 'defending') : open ? 'alert' : 'watching';
      // Recién contenida: el robot se pone verde un par de minutos (mismo criterio que la isla).
      if (!S.live && window.TSOCBot && window.TSOCBot.tone && window.TSOCBot.tone() === 'safe') S.state = 'safe';
      peek();
      S.err = r[1] ? null : 'NO_DATA';
    }).catch(function () { S.err = 'NO_DATA'; })
      .then(function () { S.busy = false; S.loadedAt = Date.now(); render(); });
  }

  function setMode(mode) {
    var now = new Date().toISOString();
    S.writeErr = null;
    proxy(IDX.set + '/_doc/settings?refresh=wait_for', 'PUT', { mode: mode, changed_by: S.user || 'analyst', changed_at: now })
      .then(function (r) {
        if (!r.ok) throw new Error(r.status === 403 ? 'No tienes permiso para cambiar el modo del Guardian.' : 'No se pudo guardar (HTTP ' + r.status + ').');
        S.loadedAt = 0; load();
      }).catch(function (e) { S.writeErr = e.message; render(); });
  }

  function undo(story) {
    proxy(IDX.resp + '/_update/' + encodeURIComponent(story.incident_id) + '?refresh=wait_for', 'POST',
      { doc: { status: 'undo_requested', undo_by: S.user || 'analyst', undo_at: new Date().toISOString() } })
      .then(function (r) {
        if (!r.ok) throw new Error('No se pudo pedir deshacer (HTTP ' + r.status + ').');
        if (window.TSOCBot && window.TSOCBot.refresh) window.TSOCBot.refresh();
        S.loadedAt = 0; load();
        [4000, 10000, 20000].forEach(function (ms) { setTimeout(function () { S.loadedAt = 0; load(); }, ms); });
      }).catch(function (e) { S.writeErr = e.message; render(); });
  }

  function me() {
    if (S.user) return S.user;
    fetch('/api/v1/configuration/account', { credentials: 'same-origin' }).then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) { S.user = (j && j.data && j.data.user_name) || 'analyst'; }).catch(function () { S.user = 'analyst'; });
    return null;
  }

  // ---------------------------------------------------------------- vista
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function ago(iso) {
    if (!iso) return '';
    var s = Math.max(0, (Date.now() - Date.parse(iso)) / 1000);
    if (s < 60) return 'hace un momento'; if (s < 3600) return 'hace ' + Math.floor(s / 60) + ' min';
    if (s < 86400) return 'hace ' + Math.floor(s / 3600) + ' h'; return 'hace ' + Math.floor(s / 86400) + ' d';
  }

  // Robot en SVG: los estados cambian colores y animaciones por CSS (tsocGd--watching/alert/defending/sleep).
  function robot() {
    // Mismo robot holográfico que el asistente flotante (triplesoc-assistant.js), en grande.
    if (window.TSOCBot) return '<div class="tsocGd__holo">' + window.TSOCBot.svg('tsocAs__bot--hero') +
      '<i class="tsocGd__orbit"></i><i class="tsocGd__orbit tsocGd__orbit--2"></i><i class="tsocGd__base"></i></div>';
    return '<svg class="tsocGd__bot" viewBox="0 0 200 220" aria-hidden="true">' +
      '<ellipse class="tsocGd__shadow" cx="100" cy="208" rx="52" ry="7"/>' +
      '<g class="tsocGd__body">' +
      '<line x1="100" y1="22" x2="100" y2="44" class="tsocGd__wire"/><circle cx="100" cy="18" r="8" class="tsocGd__antenna"/>' +
      '<rect x="40" y="44" width="120" height="92" rx="30" class="tsocGd__head"/>' +
      '<rect x="56" y="62" width="88" height="54" rx="20" class="tsocGd__face"/>' +
      '<g class="tsocGd__eyes"><ellipse cx="82" cy="88" rx="9" ry="11" class="tsocGd__eye"/><ellipse cx="118" cy="88" rx="9" ry="11" class="tsocGd__eye"/></g>' +
      '<path d="M86 104 Q100 113 114 104" class="tsocGd__mouth"/>' +
      '<rect x="56" y="62" width="88" height="4" rx="2" class="tsocGd__scan"/>' +
      '<rect x="58" y="142" width="84" height="54" rx="18" class="tsocGd__torso"/>' +
      '<path d="M100 152 l18 7 v12 c0 10 -8 16 -18 20 c-10 -4 -18 -10 -18 -20 v-12z" class="tsocGd__shield"/>' +
      '<path d="M92 170 l6 6 l11 -12" class="tsocGd__check"/>' +
      '<rect x="26" y="148" width="26" height="12" rx="6" class="tsocGd__arm tsocGd__arm--l"/>' +
      '<rect x="148" y="148" width="26" height="12" rx="6" class="tsocGd__arm tsocGd__arm--r"/>' +
      '</g></svg>';
  }

  var SAY = {
    safe: function () { return 'Amenaza contenida. El equipo quedó protegido y sigo vigilando.'; },
    watching: function () { return S.k && S.k.today ? '¡Hoy ya detuve ' + S.k.today + (S.k.today === 1 ? ' amenaza' : ' amenazas') + '! Sigo vigilando.' : 'Estoy vigilando tus equipos. Todo tranquilo por ahora.'; },
    alert: function () { return 'Hay actividad sospechosa reciente. ' + (S.mode === 'auto' ? 'Estoy listo para actuar.' : 'Revisa los incidentes: necesito tu aprobación para actuar.'); },
    defending: function () { return 'Estoy defendiendo ' + esc((S.live && S.live.agent && S.live.agent.name) || 'un equipo') + ' ahora mismo…'; },
    undoing: function () { return 'Estoy deshaciendo los cambios en ' + esc((S.live && S.live.agent && S.live.agent.name) || 'un equipo') + ' porque ' + esc((S.live && S.live.undo_by) || 'una persona') + ' lo pidió. No es un ataque.'; }
  };

  function tile(value, label, sub, tone) {
    return '<div class="tsocCc__tile tsocCc__tile--' + tone + '"><div class="tsocCc__tileLabel">' + esc(label) + '</div>' +
      '<div class="tsocCc__tileValue">' + esc(value) + '</div><div class="tsocCc__tileSub">' + esc(sub) + '</div></div>';
  }

  // Medidor del escudo: anillo SVG (r = 54 → perímetro 339,3).
  function gauge(pct, tone, sub) {
    var c = 339.3, off = (c * (1 - Math.max(0, Math.min(100, pct)) / 100)).toFixed(1);
    return '<div class="tsocCc__gauge tsocCc__gauge--' + tone + '"><svg viewBox="0 0 128 128" aria-hidden="true">' +
      '<circle cx="64" cy="64" r="54" class="tsocCc__gaugeTrack"/><circle cx="64" cy="64" r="54" class="tsocCc__gaugeArc" stroke-dasharray="' + c + '" stroke-dashoffset="' + off + '"/>' +
      '<circle cx="64" cy="64" r="44" class="tsocCc__gaugeInner"/></svg>' +
      '<div class="tsocCc__gaugeNum"><b>' + esc(pct) + '<small>%</small></b><span>Escudo</span></div>' +
      '<p>' + sub + '</p></div>';
  }

  var OUT = { executed: ['Ataque detenido', 'ok'], contained: ['Ya estaba protegido', 'ok'], undone: ['Cambio deshecho', 'undo'],
    failed: ['No se pudo actuar', 'bad'], unsupported: ['Requiere a una persona', 'warn'] };

  function story(s) {
    // Mientras se deshace se dice así, aunque la historia guardada todavía sea la de la defensa.
    var o = /^(undo_requested|undoing)$/.test(s.status) ? ['Deshaciendo los cambios…', 'undo'] : s.status === 'undo_failed' ? ['No se pudo deshacer', 'bad'] : OUT[s.story_outcome] || [s.story_outcome, 'muted'];
    var canUndo = s.status === 'executed' && /^block_usb_(storage|phone|input)$/.test(s.action);
    var ms = s.contained_ms != null ? s.contained_ms : s.response_ms;
    var speed = s.story_outcome !== 'executed' ? '' : ms != null && window.TSOCBot && window.TSOCBot.ms ? window.TSOCBot.ms(ms) : s.response_seconds != null ? s.response_seconds + ' s' : '';
    return '<li class="tsocCc__story tsocCc__story--' + o[1] + '"><i class="tsocCc__storyDot"></i><div class="tsocCc__storyBody">' +
      '<div class="tsocCc__storyHead"><b>' + esc(o[0]) + '</b><span>' + esc((s.agent && s.agent.name) || '') + '</span><time>' + esc(ago(s.story_at)) + '</time></div>' +
      '<p>' + esc(s.story) + '</p>' +
      '<div class="tsocCc__storyMeta">' +
      (s.auto ? '<span class="tsocCc__chip tsocCc__chip--auto">' + (s.reflex ? 'Reflejo automático' : 'Automático') + '</span>'
        : (s.decided_by && s.story_outcome === 'executed' ? '<span class="tsocCc__chip">Aprobado por ' + esc(s.decided_by) + '</span>' : '')) +
      (speed ? '<span class="tsocCc__chip tsocCc__chip--mono">' + esc(speed) + '</span>' : '') +
      '<span class="tsocCc__chip tsocCc__chip--mono">' + esc(s.incident_id) + '</span>' +
      '<span class="tsocCc__storyBtns"><a class="tsocCc__link" data-nav href="/app/dashboards#/view/triplesoc-incidents">' + (/^RFX-/.test(s.incident_id) ? 'Incidentes' : 'Ver incidente') + '</a>' +
      (canUndo ? '<button class="tsocCc__undo" data-undo="' + esc(s.incident_id) + '">Deshacer</button>' : '') + '</span></div></div></li>';
  }

  // ---------------------------------------------------------------- respuesta en directo (carril rápido)
  // triplesoc-responder deja una traza por respuesta (kind=trace) y su pulso (documento "pulse") en el
  // índice del Guardian. Aquí solo se leen; los tiempos son los que midió el servicio.
  function peek() {
    S.peekAt = Date.now();
    Promise.all([
      search(IDX.set, { size: 6, sort: [{ at: { order: 'desc', unmapped_type: 'date' } }], query: { term: { kind: 'trace' } } }),
      search(IDX.set, { size: 1, query: { ids: { values: ['pulse'] } } })
    ]).then(function (r) {
      if (r[0]) S.traces = r[0].hits.hits.map(function (h) { return h._source; });
      S.pulse = r[1] && r[1].hits.hits[0] ? r[1].hits.hits[0]._source : null;
      var t = S.traces[0], sig = t ? t.trace_id + '|' + t.status : '';
      if (S.lastSig != null && sig !== S.lastSig) {
        // Algo acaba de pasar: se reproduce la traza y se refrescan las historias y los indicadores.
        if (t && Date.now() - Date.parse(t.at) < 120000) S.replay = t.trace_id + '|' + t.status;
        S.loadedAt = 0;
      }
      S.lastSig = sig;
      paintLive();
    });
  }

  function acted(t) { return t && (t.status === 'verified' || t.status === 'sent'); }
  function speedValue(k) {
    var t = S.traces.filter(acted)[0];
    if (t && t.total_ms != null && window.TSOCBot && window.TSOCBot.ms) return window.TSOCBot.ms(t.total_ms);
    return k.speed != null ? k.speed + ' s' : '—';
  }
  function speedSub() { return S.traces.filter(acted)[0] ? 'última respuesta automática' : 'desde que empieza el ataque'; }

  function laneHtml() {
    var p = S.pulse, fresh = p && Date.now() - Date.parse(p.at) < 20000, on = fresh && p.lane === 'online';
    var bits = [];
    if (on) {
      bits.push(esc(p.events_1m || 0) + ' eventos analizados en el último minuto');
      if (p.read_lag_ms != null) bits.push('lectura con ' + esc(p.read_lag_ms) + ' ms de retraso');
      bits.push(p.armed && p.mode === 'auto' ? 'armado: actúa solo' : p.mode === 'auto' ? 'sin permiso de ejecución' : 'modo manual: detecta y espera');
    }
    return '<span class="tsocLv__lane tsocLv__lane--' + (on ? 'on' : 'off') + '"><i></i>' +
      (on ? 'Carril rápido en línea' : fresh ? 'Carril rápido sin lectura de alertas' : 'Carril rápido sin señal') + '</span>' +
      (bits.length ? '<span class="tsocLv__laneInfo">' + bits.join(' · ') + '</span>' : '');
  }

  function paintLive() {
    paintOps();
    var box = root && root.querySelector('[data-live]');
    if (!box || !window.TSOCBot || !window.TSOCBot.trace) return;
    var t = S.traces[0], p = S.pulse;
    var key = JSON.stringify([S.traces.map(function (x) { return x.trace_id + x.status + (x.steps || []).length; }),
      p && [p.lane, p.events_1m, p.read_lag_ms, p.mode, p.armed, Date.now() - Date.parse(p.at) < 20000]]);
    if (key === S.liveKey) return;
    var replay = t && S.replay === t.trace_id + '|' + t.status;
    // Solo cambió el pulso: se actualiza la cabecera y la traza no se vuelve a animar.
    var lane = box.querySelector('[data-lane]');
    if (lane && S.liveKey && JSON.parse(S.liveKey)[0].join() === JSON.parse(key)[0].join() && !replay) { lane.innerHTML = laneHtml(); S.liveKey = key; return; }
    S.liveKey = key; S.replay = null;
    box.innerHTML = '<div class="tsocGd__feedHead tsocLv__head"><h2>Respuesta en directo</h2><div class="tsocLv__laneWrap" data-lane>' + laneHtml() + '</div></div>' +
      (t ? window.TSOCBot.trace(t, { replay: replay }) +
        (S.traces.length > 1 ? '<ul class="tsocLv__hist">' + S.traces.slice(1).map(function (x) { return window.TSOCBot.traceRow(x, ago(x.at)); }).join('') + '</ul>' : '') +
        '<p class="tsocLv__note">Cada etapa se marca cuando se cumple. Tiempos medidos por el servicio' + (t.clock_synced === false ? ' (desde la detección: el reloj del equipo no coincide con el del servidor)' : ', contados desde que Windows registró la conexión') + '. La animación los repite a velocidad legible.</p>'
        : (window.TSOCBot.idle ? window.TSOCBot.idle() : '') + '<p class="tsocLv__note">Sin respuestas todavía. Cuando alguien conecte una memoria USB o un teléfono no autorizado, cada etapa se marcará aquí con su tiempo medido.</p>');
  }

  // Flujo del sistema y registro de actividad: datos del pulso del servicio (cada 2 s), sin tocar el resto.
  function paintOps() {
    if (!root) return;
    var p = S.pulse, k = S.k || {}, fresh = p && Date.now() - Date.parse(p.at) < 20000, on = fresh && p.lane === 'online';
    var t = S.traces.filter(acted)[0], ms = window.TSOCBot && window.TSOCBot.ms;
    var pipe = root.querySelector('[data-pipe]');
    if (pipe) {
      var nodes = [
        ['Equipos', (k.endpoints || 0) + ' activos', 'agente en cada equipo', k.endpoints ? 'ok' : 'off'],
        ['Detección', (k.rules || 0) + ' reglas IA', 'motor de reglas TripleSOC', 'ok'],
        ['Carril rápido', on ? (p.read_lag_ms != null ? p.read_lag_ms + ' ms' : 'en línea') : 'sin señal', on ? (p.events_1m || 0) + ' alertas/min' : 'servicio no responde', on ? 'ok' : 'off'],
        ['Política', S.mode === 'auto' ? 'automática' : 'con aprobación', fresh && p.armed ? 'ejecución habilitada' : 'ejecución no habilitada', S.mode === 'auto' ? 'ok' : 'warn'],
        ['Respuesta', (k.auto || 0) + ' automáticas', 'últimos 7 días', 'ok'],
        ['Verificación', t && ms ? ms(t.total_ms) : '—', t ? (t.status === 'verified' ? 'confirmada por el equipo' : 'orden entregada') : 'sin respuestas aún', t ? 'ok' : 'off']
      ];
      var html = nodes.map(function (n, i) {
        return '<div class="tsocCc__node tsocCc__node--' + n[3] + '"><span class="tsocCc__nodeIdx">' + ('0' + (i + 1)) + '</span><i></i>' +
          '<b>' + esc(n[0]) + '</b><strong>' + esc(n[1]) + '</strong><small>' + esc(n[2]) + '</small></div>';
      }).join('<span class="tsocCc__wire' + (on ? ' is-live' : '') + '"></span>');
      if (pipe.getAttribute('data-k') !== html) { pipe.innerHTML = html; pipe.setAttribute('data-k', html); }
    }
    var log = root.querySelector('[data-oplog]');
    if (log) {
      var feed = (fresh && p.activity) || [], key = fresh ? p.at + feed.length : 'off';
      if (log.getAttribute('data-k') !== key) {
        log.setAttribute('data-k', key);
        log.innerHTML = feed.length ? feed.slice().reverse().map(function (f) {
          return '<div class="tsocIs__ev tsocIs__ev--' + esc(f.kind) + '"><time>' + esc(String(f.at || '').slice(11, 19)) + '</time><em>' + esc(FEED_TAG[f.kind] || f.kind) + '</em><span>' +
            esc(f.text) + (f.n > 1 ? ' <b>×' + esc(f.n) + '</b>' : '') + '</span></div>';
        }).join('') : '<div class="tsocCc__logEmpty">' + (fresh ? 'Vigilando. Aún no ha llegado ninguna alerta desde que arrancó el servicio.' : 'Sin señal del servicio.') + '</div>';
      }
      var stat = root.querySelector('[data-opstat]');
      if (stat) stat.textContent = fresh ? (p.events_total || 0) + ' alertas evaluadas · ' + (p.signals_total || 0) + ' señales inmediatas · servicio ' + (p.version || '') : 'sin señal';
    }
  }
  var FEED_TAG = { alert: 'alerta', signal: 'señal', act: 'acción', cmd: 'comando', svc: 'servicio', chat: 'chat', warn: 'aviso' };
  var STATE = { safe: 'Protegido · amenaza contenida', watching: 'Operativo · vigilando', alert: 'Amenaza sin contener', defending: 'Defendiendo un equipo', undoing: 'Deshaciendo los cambios' };

  var root = null;
  function render() {
    if (!root) return;
    var k = S.k || {}, auto = S.mode === 'auto', state = S.state;
    var shield = k.shield != null ? k.shield : 100, shieldTone = shield >= 90 ? 'ok' : shield >= 60 ? 'warn' : 'bad';
    // La pantalla ya está dibujada y nada cambió: solo se actualiza el estado, para no reiniciar animaciones.
    var sig = JSON.stringify([k, S.mode, S.stories.map(function (s) { return s.incident_id + s.status + s.story_outcome; }), S.writeErr, state, S.changed && S.changed.changed_at]);
    root.className = 'tsocInc tsocGd tsocGd--' + state + (auto ? ' tsocGd--auto' : '');
    if (root.querySelector('.tsocCc') && root.getAttribute('data-k') === sig) return;
    root.setAttribute('data-k', sig);
    root.innerHTML = '<div class="tsocInc__page tsocGd__page tsocCc">' +
      '<header class="tsocCc__bar"><div class="tsocCc__title"><span>TripleSOC · agente de respuesta autónoma</span><h1>Guardian</h1></div>' +
      '<div class="tsocCc__status tsocCc__status--' + state + '"><i></i>' + esc(STATE[state]) + '</div>' +
      '<div class="tsocCc__modeBox"><div class="tsocCc__seg" role="group" aria-label="Modo de respuesta">' +
      '<button class="' + (auto ? '' : 'is-on') + '"' + (auto ? ' data-act="toggle"' : '') + ' aria-pressed="' + !auto + '">Manual</button>' +
      '<button class="' + (auto ? 'is-on' : '') + '"' + (auto ? '' : ' data-act="toggle"') + ' aria-pressed="' + auto + '">Automático</button></div>' +
      '<small>' + (auto ? 'Actúa solo y lo informa; todo se puede deshacer' : 'Recomienda y espera la aprobación de una persona') +
      (S.changed && S.changed.changed_by ? ' · cambiado por ' + esc(S.changed.changed_by) + ' ' + esc(ago(S.changed.changed_at)) : '') + '</small></div></header>' +
      (S.writeErr ? '<div class="tsocInc__warn">' + esc(S.writeErr) + '</div>' : '') +
      '<section class="tsocCc__hero"><div class="tsocCc__core"><div class="tsocGd__botWrap">' + robot() + '</div>' +
      '<div class="tsocCc__say">' + SAY[state]() + '</div></div>' +
      gauge(shield, shieldTone, k.attacks ? '<b>' + esc(Math.round(shield * k.attacks / 100)) + ' de ' + esc(k.attacks) + '</b> amenazas importantes controladas en 7 días' : 'Sin amenazas importantes en 7 días') +
      '<div class="tsocCc__tiles">' +
      tile(k.today || 0, 'Amenazas detenidas hoy', (k.week || 0) + ' en los últimos 7 días', 'green') +
      tile(speedValue(k), 'Tiempo de respuesta', speedSub(), 'cyan') +
      tile(k.auto || 0, 'Acciones automáticas', 'últimos 7 días', 'violet') +
      tile(k.endpoints || 0, 'Equipos vigilados', 'activos en 24 h', 'blue') +
      tile(k.rules || 0, 'Reglas aprendidas', 'creadas por la IA y aprobadas', 'amber') +
      tile(k.attacks || 0, 'Amenazas importantes', 'incidentes altos o críticos, 7 días', 'red') + '</div></section>' +
      '<section class="tsocCc__pipe" data-pipe aria-label="Flujo del sistema"></section>' +
      '<section class="tsocInc__card tsocGd__live" data-live></section>' +
      '<div class="tsocCc__cols"><section class="tsocInc__card tsocCc__panel"><div class="tsocCc__panelHead"><h2>Registro de actividad y comandos</h2><span data-opstat></span></div>' +
      '<div class="tsocIs__feed tsocCc__log" data-oplog></div><p class="tsocCc__foot">Cada alerta evaluada y cada comando interno (API del manager, indexer, IA, equipo), sin resumir · horas en UTC · se actualiza cada 2 s</p></section>' +
      '<section class="tsocInc__card tsocCc__panel"><div class="tsocCc__panelHead"><h2>Informe de acciones</h2><button class="tsocCc__link" data-act="refresh">' + (S.busy ? 'Actualizando…' : 'Actualizar') + '</button></div>' +
      (S.stories.length ? '<ul class="tsocCc__stories">' + S.stories.map(story).join('') + '</ul>'
        : '<div class="tsocInc__empty"><b>Todavía no he tenido que actuar.</b><span>Cuando detecte un ataque y lo detenga, quedará aquí explicado con palabras sencillas.</span></div>') +
      '</section></div></div>';
    S.liveKey = null; paintLive();
  }

  function onClick(e) {
    var t = e.target.closest('[data-act],[data-undo],[data-nav]');
    if (!t) return;
    if (t.hasAttribute('data-nav')) {
      if (e.button !== 0 || e.ctrlKey || e.metaKey || e.shiftKey) return;
      e.preventDefault(); history.pushState(null, '', t.getAttribute('href')); window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
      return;
    }
    if (t.hasAttribute('data-undo')) {
      var s = S.stories.filter(function (x) { return x.incident_id === t.getAttribute('data-undo'); })[0];
      if (s && window.confirm('¿Deshacer "' + s.action_label + '" en ' + ((s.agent && s.agent.name) || 'el equipo') + '?')) undo(s);
      return;
    }
    var act = t.getAttribute('data-act');
    if (act === 'refresh') { S.loadedAt = 0; load(); }
    if (act === 'toggle') {
      var toAuto = S.mode !== 'auto';
      var msg = toAuto
        ? '¿Activar el MODO AUTOMÁTICO?\n\nEl Guardian ejecutará solo, sin pedir permiso, las acciones de defensa que recomiende (por ejemplo bloquear el almacenamiento USB de un equipo). Todo queda registrado y se puede deshacer.'
        : '¿Volver al MODO MANUAL?\n\nEl Guardian seguirá vigilando y recomendando, pero esperará tu aprobación antes de actuar.';
      if (window.confirm(msg)) setMode(toAuto ? 'auto' : 'manual');
    }
  }

  function mount() {
    if (root) return root;
    root = document.createElement('div');
    root.id = 'tsoc-guardian';
    root.className = 'tsocInc tsocGd';
    root.addEventListener('click', onClick);
    document.body.appendChild(root);
    S.loadedAt = 0; load();
    return root;
  }
  function unmount() { if (root) { root.remove(); root = null; } }

  function place() {
    var host = document.querySelector('.app-wrapper') || document.querySelector('#app-wrapper');
    var top = 48, left = 0;
    if (host) { var r = host.getBoundingClientRect(); top = Math.max(0, r.top); left = Math.max(0, r.left); }
    root.style.top = top + 'px'; root.style.left = left + 'px';
  }

  function tick() {
    try {
      var here = location.pathname + decodeURIComponent(location.hash);
      if (!ROUTE.test(here)) { unmount(); return; }
      me(); mount();
      if (!root.isConnected) document.body.appendChild(root);
      place();
      // Más a menudo mientras defiende, para ver el cambio de estado en directo.
      if (!S.busy && Date.now() - S.loadedAt > (S.state === 'watching' ? 15000 : 4000)) load();
      // La respuesta en directo se consulta aparte y más a menudo: es una búsqueda mínima.
      if (!document.hidden && Date.now() - S.peekAt > 1500) peek();
    } catch (err) { /* nunca romper la página */ }
  }
  setInterval(tick, 500);
})();
/* ==== fin TripleSOC guardian ==== */
