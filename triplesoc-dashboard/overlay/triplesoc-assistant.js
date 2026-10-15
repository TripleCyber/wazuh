/* ==== TripleSOC assistant ====
   "Guardian": asistente flotante presente en todas las pantallas del dashboard.
   - Robot holográfico abajo a la derecha: respira, sigue el ratón con los ojos y cambia de color según el estado
     (vigilando, pensando, hablando, alerta, defendiendo).
   - Se llama con un clic, con Alt+G o por voz (micrófono). Se presenta al entrar en cada sección.
   - Conversación: cada pregunta se guarda como documento kind=ask en triplesoc-incidents-guardian con la sesión del
     usuario; el servicio triplesoc-responder la contesta en 1-3 s con datos reales (solo lectura).
   - Las acciones que propone son botones de una lista cerrada (navegar o el interruptor de modo, que pide confirmación).
   apply-branding.sh lo AÑADE al final de core.entry.js: no modifica código existente. Nunca rompe la página. */
;(function () {
  'use strict';
  if (window.__tsocAssistant) return;
  window.__tsocAssistant = true;

  var IDX = 'triplesoc-incidents-guardian';
  var RESP = 'triplesoc-incidents-responses';
  var INC = 'triplesoc-incidents';
  var A = { open: false, msgs: [], thinking: false, state: 'idle', mood: 'calm', user: null, mode: null, sound: true,
    speaking: false, listening: false, section: null, seen: {}, unread: 0, polled: 0, greeted: false };

  function store(k, v) { try { if (v === undefined) return localStorage.getItem('tsocAs.' + k); localStorage.setItem('tsocAs.' + k, v); } catch (e) { return null; } }
  function sstore(k, v) { try { if (v === undefined) return sessionStorage.getItem('tsocAs.' + k); sessionStorage.setItem('tsocAs.' + k, v); } catch (e) { return null; } }
  A.sound = store('sound') !== 'off';
  A.hidden = store('robot') === 'off';   // el robot de abajo se puede ocultar; la isla sigue visible

  // ---------------------------------------------------------------- secciones (presentación al entrar)
  var SECTIONS = [
    { id: 'guardian', re: /view\/triplesoc-guardian/, name: 'Guardian',
      say: 'Este es mi centro de mando. Aquí ves lo que he detenido, el escudo de protección y el interruptor para dejarme actuar solo o con tu aprobación.' },
    { id: 'overview', re: /view\/triplesoc-overview/, name: 'Overview',
      say: 'Este es el resumen general: cuántas alertas llegan, qué tan graves son y qué equipos están conectados. Es la foto de la salud de tu empresa en un vistazo.' },
    { id: 'incidents', re: /view\/triplesoc-incidents/, name: 'Incidents',
      say: 'Aquí agrupo las alertas sueltas en incidentes, como un detective que une pistas. Cada uno trae una puntuación de riesgo y mi recomendación de qué hacer.' },
    { id: 'rules', re: /view\/triplesoc-rules/, name: 'AI Rules',
      say: 'Esta es mi fábrica de reglas. Me describes en palabras lo que quieres vigilar y yo escribo la regla, la valido y la pruebo en silencio antes de activarla.' },
    { id: 'hunting', re: /^\/app\/threat-hunting/, name: 'Analytics',
      say: 'Aquí puedes investigar cada evento con detalle: qué pasó, en qué equipo y a qué hora. Es la lupa del analista.' },
    { id: 'mitre', re: /^\/app\/mitre-attack/, name: 'Attack Map',
      say: 'Este es el mapa de técnicas de ataque de MITRE, el estándar mundial. Te muestra qué tipo de ataques hemos visto y en qué fase del ataque estaban.' },
    { id: 'endpoints', re: /^\/app\/endpoints-summary/, name: 'Entities',
      say: 'Estos son los equipos que protejo. Cada uno tiene un agente que me cuenta lo que pasa en él.' },
    { id: 'groups', re: /^\/app\/endpoint-groups/, name: 'Trust Zones',
      say: 'Aquí se organizan los equipos en grupos, para aplicar a cada uno la vigilancia que necesita.' },
    { id: 'apis', re: /^\/app\/server-apis/, name: 'APIs',
      say: 'Esta es la conexión técnica con el cerebro de Wazuh. Normalmente solo la usa el equipo técnico.' }
  ];
  var ROUTES = {
    open_incidents: '/app/dashboards#/view/triplesoc-incidents', open_ai_rules: '/app/dashboards#/view/triplesoc-rules',
    open_guardian: '/app/dashboards#/view/triplesoc-guardian', open_overview: '/app/dashboards#/view/triplesoc-overview',
    open_threat_hunting: '/app/threat-hunting', open_endpoints: '/app/endpoints-summary'
  };
  var LABELS = { open_incidents: 'Ver incidentes', open_ai_rules: 'Ver reglas de IA', open_guardian: 'Abrir mi centro de mando',
    open_overview: 'Ver resumen', open_threat_hunting: 'Investigar eventos', open_endpoints: 'Ver equipos',
    mode_auto: '🤖 Activar modo automático', mode_manual: '🧑 Volver a modo manual' };
  var CHIPS = ['¿Estoy seguro ahora mismo?', '¿Qué pasó hoy?', 'Explícame esta pantalla', '¿Qué hiciste por mí esta semana?'];

  function section() {
    var here = location.pathname + decodeURIComponent(location.hash);
    for (var i = 0; i < SECTIONS.length; i++) if (SECTIONS[i].re.test(here)) return SECTIONS[i];
    return null;
  }

  // ---------------------------------------------------------------- datos
  function search(index, body) {
    return fetch('/internal/search/opensearch', {
      method: 'POST', credentials: 'same-origin', headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify({ params: { index: index, body: body } })
    }).then(function (r) { return r.ok ? r.json().then(function (j) { return j.rawResponse; }) : null; }).catch(function () { return null; });
  }
  function proxy(path, method, body) {
    return fetch('/api/console/proxy?path=' + encodeURIComponent(path) + '&method=' + method, {
      method: 'POST', credentials: 'same-origin', headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
      body: JSON.stringify(body)
    });
  }
  function me() {
    if (A.user) return A.user;
    fetch('/api/v1/configuration/account', { credentials: 'same-origin' }).then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) { A.user = (j && j.data && j.data.user_name) || 'analyst'; }).catch(function () { A.user = 'analyst'; });
    return null;
  }

  // Estado global del robot. Defender y deshacer son cosas distintas y se dicen distinto:
  //   defending = hay una acción de defensa en curso; undoing = una persona pidió deshacer un cambio y se está retirando;
  //   alert = hay incidentes altos recientes que nadie ha contenido todavía.
  function syncState() {
    var prev = A.state, a = LV.active, host = (a && a.agent && a.agent.name) || 'un equipo';
    var tone = situation().tone;
    A.state = a ? (isUndo(a) ? 'undoing' : 'defending') : tone === 'safe' ? 'safe' : (A.threats || tone === 'danger') ? 'alert' : 'idle';
    if (A.state !== prev && A.state === 'safe') bubble('Amenaza contenida. El equipo quedó protegido.', [['open_guardian', 'Ver qué hice']]);
    if (A.state !== prev && A.state === 'defending') bubble('Estoy defendiendo ' + host + ' ahora mismo. Pulsa para ver cada paso.', [['open_guardian', 'Ver en directo']]);
    if (A.state !== prev && A.state === 'undoing') bubble('Estoy deshaciendo los cambios en ' + host + ' porque ' + (a.undo_by || 'una persona') + ' lo pidió. No es un ataque.', [['open_guardian', 'Ver en directo']]);
    paint();
  }
  function poll() {
    A.polled = Date.now();
    search(IDX, { size: 1, query: { ids: { values: ['settings'] } } }).then(function (r) {
      var s = r && r.hits.hits[0] && r.hits.hits[0]._source;
      A.mode = s && s.mode === 'auto' ? 'auto' : 'manual';
      paint();
    });
    // Amenazas sin contener: incidentes altos o críticos de los últimos 15 min que no tienen una respuesta aplicada.
    search(INC, { size: 20, _source: ['incident_id'], query: { bool: { filter: [{ terms: { status: ['new', 'investigating'] } },
      { range: { severity_rank: { gte: 3 } } }, { range: { last_seen: { gte: 'now-15m' } } }] } } }).then(function (r) {
      var ids = r ? r.hits.hits.map(function (h) { return h._source.incident_id; }).filter(Boolean) : [];
      if (!ids.length) { A.threats = 0; syncState(); paintIsland(); return; }
      search(RESP, { size: 50, _source: ['incident_id', 'status', 'story_outcome'], query: { ids: { values: ids } } }).then(function (x) {
        var done = {};
        (x ? x.hits.hits : []).forEach(function (h) {
          var d = h._source;
          if (/^(executed|executing)$/.test(d.status) || d.story_outcome === 'contained') done[d.incident_id] = 1;
        });
        A.threats = ids.filter(function (id) { return !done[id]; }).length;
        syncState(); paintIsland();
      });
    });
    // Vulnerabilidades críticas que el detector acaba de anunciar (activa = riesgo; resuelta = ya corregida en el equipo).
    search('triplesoc-alerts-*', { size: 1, sort: [{ timestamp: 'desc' }],
      _source: ['timestamp', 'agent.name', 'data.vulnerability.cve', 'data.vulnerability.status', 'data.vulnerability.package.name'],
      query: { bool: { filter: [{ term: { 'rule.groups': 'vulnerability-detector' } }, { term: { 'data.vulnerability.severity': 'Critical' } },
        { range: { timestamp: { gte: 'now-15m' } } }] } } }).then(function (r) {
      var h = r && r.hits.hits[0] && r.hits.hits[0]._source, v = h && h.data && h.data.vulnerability;
      A.vuln = v ? { at: h.timestamp, host: (h.agent && h.agent.name) || '', cve: v.cve || '', pkg: (v.package && v.package.name) || '',
        solved: /^solved$/i.test(v.status || '') } : null;
      paintIsland();
    });
  }

  // ---------------------------------------------------------------- voz
  function voice() {
    if (!window.speechSynthesis) return null;
    var vs = speechSynthesis.getVoices();
    return vs.filter(function (v) { return /^es(-|_)/i.test(v.lang) && /google|natural|online/i.test(v.name); })[0] ||
      vs.filter(function (v) { return /^es(-|_)/i.test(v.lang); })[0] || null;
  }
  function speak(text) {
    if (!A.sound || !window.speechSynthesis || !text) return;
    if (A.hidden && !A.open) return;   // robot oculto: tampoco habla solo
    try {
      speechSynthesis.cancel();
      // Sin emojis ni símbolos: la voz los leería en alto.
      var u = new SpeechSynthesisUtterance(text.replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]|[☀-➿️]/g, ''));
      var v = voice(); if (v) u.voice = v;
      u.lang = (v && v.lang) || 'es-ES'; u.rate = 1.04; u.pitch = 1.08;
      u.onstart = function () { A.speaking = true; paint(); };
      u.onend = u.onerror = function () { A.speaking = false; paint(); };
      speechSynthesis.speak(u);
    } catch (e) { /* sin voz */ }
  }
  var rec = null;
  function listen() {
    var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR) { addMsg('bot', 'Tu navegador no me deja escucharte. Escríbeme y te respondo.'); return; }
    if (A.listening && rec) { rec.stop(); return; }
    try {
      rec = new SR(); rec.lang = 'es-ES'; rec.interimResults = true; rec.maxAlternatives = 1;
      rec.onstart = function () { A.listening = true; paint(); };
      rec.onend = function () { A.listening = false; paint(); };
      rec.onerror = function () { A.listening = false; paint(); };
      rec.onresult = function (e) {
        var t = Array.prototype.map.call(e.results, function (r) { return r[0].transcript; }).join(' ');
        var inp = root && root.querySelector('[data-as-input]'); if (inp) inp.value = t;
        if (e.results[e.results.length - 1].isFinal) ask(t);
      };
      rec.start();
    } catch (e) { A.listening = false; paint(); }
  }

  // ---------------------------------------------------------------- conversación
  function addMsg(who, text, suggest) {
    A.msgs.push({ who: who, text: text, suggest: suggest || [], at: Date.now() });
    if (A.msgs.length > 40) A.msgs.shift();
    if (who === 'bot' && !A.open) A.unread++;
    paint(true);
  }

  function ask(text) {
    text = String(text || '').trim();
    if (!text || A.thinking) return;
    var inp = root && root.querySelector('[data-as-input]'); if (inp) inp.value = '';
    var history = A.msgs.slice(-8).map(function (m) { return { role: m.who === 'me' ? 'user' : 'guardian', text: m.text }; });
    addMsg('me', text);
    A.thinking = true; paint();
    var id = 'ask-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
    var sec = section();
    proxy(IDX + '/_doc/' + id + '?op_type=create&refresh=wait_for', 'PUT', {
      kind: 'ask', status: 'pending', by: A.user || 'analyst', at: new Date().toISOString(),
      page: sec ? sec.name : (location.pathname.replace(/^\/app\//, '') || 'dashboard'), question: text.slice(0, 1000), history: history
    }).then(function (r) {
      if (!r.ok) throw new Error(r.status === 403 ? 'perm' : 'http');
      var t0 = Date.now();
      (function wait() {
        search(IDX, { size: 1, query: { ids: { values: [id] } } }).then(function (res) {
          var d = res && res.hits.hits[0] && res.hits.hits[0]._source;
          if (d && d.status === 'answered') {
            A.thinking = false; A.mood = d.mood || 'calm';
            addMsg('bot', d.answer, d.suggest || []); speak(d.answer); return;
          }
          if (Date.now() - t0 > 45000) { A.thinking = false; addMsg('bot', 'Estoy tardando demasiado en pensar. ¿Lo intentamos otra vez en un momento?'); return; }
          setTimeout(wait, 900);
        });
      })();
    }).catch(function (e) {
      A.thinking = false;
      addMsg('bot', e.message === 'perm' ? 'Tu usuario no tiene permiso para hablar conmigo todavía. Pídeselo al administrador.' : 'No pude enviar tu pregunta. ¿Lo intentamos otra vez?');
    });
  }

  function doSuggest(code) {
    if (ROUTES[code]) {
      history.pushState(null, '', ROUTES[code]); window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
      return;
    }
    if (code === 'mode_auto' || code === 'mode_manual') {
      var auto = code === 'mode_auto';
      if (!window.confirm(auto ? '¿Activar el MODO AUTOMÁTICO?\n\nActuaré solo, sin pedir permiso, con las defensas que recomiende. Todo queda registrado y se puede deshacer.'
        : '¿Volver al MODO MANUAL?\n\nSeguiré vigilando, pero esperaré tu aprobación antes de actuar.')) return;
      proxy(IDX + '/_doc/settings?refresh=wait_for', 'PUT', { mode: auto ? 'auto' : 'manual', changed_by: A.user || 'analyst', changed_at: new Date().toISOString() })
        .then(function (r) {
          if (!r.ok) throw new Error();
          A.mode = auto ? 'auto' : 'manual';
          var t = auto ? 'Listo: desde ahora actúo solo y te cuento todo lo que haga. Puedes deshacerlo cuando quieras.' : 'Hecho: vuelvo a pedirte permiso antes de actuar.';
          addMsg('bot', t); speak(t);
        }).catch(function () { addMsg('bot', 'No pude cambiar el modo: tu usuario no tiene permiso.'); });
    }
  }

  // ---------------------------------------------------------------- robot (SVG)
  var uid = 0;
  function bot(cls) {
    var p = 'tsocAsG' + (uid++);
    return '<svg class="tsocAs__bot ' + (cls || '') + '" viewBox="0 0 120 120" aria-hidden="true"><defs>' +
      '<linearGradient id="' + p + 'h" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F8FAFC"/><stop offset=".55" stop-color="#CBD5E1"/><stop offset="1" stop-color="#94A3B8"/></linearGradient>' +
      '<linearGradient id="' + p + 'v" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0B1220"/><stop offset="1" stop-color="#111827"/></linearGradient>' +
      '<radialGradient id="' + p + 'g" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="var(--as-c)" stop-opacity=".55"/><stop offset="1" stop-color="var(--as-c)" stop-opacity="0"/></radialGradient>' +
      '</defs>' +
      '<circle cx="60" cy="62" r="58" fill="url(#' + p + 'g)" class="tsocAs__aura"/>' +
      '<g class="tsocAs__float">' +
      '<line x1="60" y1="14" x2="60" y2="26" stroke="#94A3B8" stroke-width="3" stroke-linecap="round"/>' +
      '<circle cx="60" cy="11" r="5" class="tsocAs__ant"/>' +
      '<rect x="20" y="26" width="80" height="66" rx="24" fill="url(#' + p + 'h)" stroke="#E2E8F0" stroke-width="1.5"/>' +
      '<rect x="14" y="48" width="8" height="20" rx="4" fill="#94A3B8"/><rect x="98" y="48" width="8" height="20" rx="4" fill="#94A3B8"/>' +
      '<rect x="29" y="37" width="62" height="44" rx="16" fill="url(#' + p + 'v)"/>' +
      '<path d="M33 41 Q60 34 87 41" stroke="rgba(255,255,255,.18)" stroke-width="3" fill="none" stroke-linecap="round"/>' +
      '<g class="tsocAs__eyes"><rect x="41" y="50" width="12" height="15" rx="6" class="tsocAs__eye"/><rect x="67" y="50" width="12" height="15" rx="6" class="tsocAs__eye"/></g>' +
      '<g class="tsocAs__mouth"><rect x="50" y="70" width="3" height="4" rx="1.5"/><rect x="55" y="69" width="3" height="6" rx="1.5"/><rect x="60" y="68" width="3" height="8" rx="1.5"/><rect x="65" y="69" width="3" height="6" rx="1.5"/><rect x="70" y="70" width="3" height="4" rx="1.5"/></g>' +
      '<rect x="31" y="39" width="58" height="2.5" rx="1.2" class="tsocAs__scan"/>' +
      '</g></svg>';
  }

  // ---------------------------------------------------------------- vista
  var root = null, bubbleTimer = null;
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }

  // ---------------------------------------------------------------- respuesta en directo (carril rápido)
  // Traza que deja triplesoc-responder por cada respuesta inmediata: se dibuja igual en la pantalla Guardian
  // (completa) y en la tarjeta del asistente (compacta). Los tiempos vienen medidos del servicio.
  function fmtMs(ms) {
    if (ms == null) return '—';
    return ms < 1000 ? ms + ' ms' : (ms / 1000).toFixed(ms < 10000 ? 2 : 1).replace('.', ',') + ' s';
  }
  var TRACE_STATE = { verified: ['Contenido y verificado', 'ok'], sent: ['Orden entregada al equipo', 'ok'], waiting: ['En espera de una persona', 'warn'],
    failed: ['No se pudo actuar', 'bad'], allowed: ['Dispositivo autorizado', 'muted'], observed: ['Solo observado', 'muted'], running: ['En curso', 'warn'] };

  // ---- Pipeline con lista de comprobación: siempre se ven TODAS las etapas y cada una se marca al cumplirse.
  //   done = hecha (✓) · run = en curso (gira) · hold = espera a una persona (pausa) · fail = falló (✕)
  //   todo = aún no toca · skip = no aplica en este caso (—)
  var MARK = {
    done: '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M3.6 8.6l2.9 2.9 5.9-6.6"/></svg>',
    fail: '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M4.6 4.6l6.8 6.8M11.4 4.6l-6.8 6.8"/></svg>',
    hold: '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M6 4.6v6.8M10 4.6v6.8"/></svg>',
    skip: '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M4.6 8h6.8"/></svg>', run: '', todo: '' };
  var MARK_ES = { done: 'hecho', fail: 'falló', hold: 'en espera', skip: 'no aplica', run: 'en curso', todo: 'pendiente' };
  var STAGES = [
    ['connect', 'Conexión', 'Un dispositivo se conecta al equipo'], ['detect', 'Detección', 'La regla lo reconoce en tiempo real'],
    ['decide', 'Decisión', 'Política: autorizado, manual o automático'], ['act', 'Acción', 'Orden de bloqueo al equipo'],
    ['verify', 'Verificación', 'El equipo confirma que se aplicó'], ['explain', 'Informe', 'Historia sencilla y aviso al canal']];

  function pipeHtml(p, opt) {
    opt = opt || {};
    var items = p.items, ok = items.filter(function (s) { return s.state === 'done'; }).length;
    var applies = items.filter(function (s) { return s.state !== 'skip'; }).length;
    return '<div class="tsocLv tsocLv--pl tsocLv--' + p.tone + (opt.compact ? ' tsocLv--compact' : '') + (opt.replay ? ' is-replay' : '') + '" style="--n:' + items.length + '">' +
      '<div class="tsocLv__top"><span class="tsocLv__state"><i></i>' + esc(p.state) + '</span>' +
      '<span class="tsocLv__host">' + esc(p.host || '') + '</span>' +
      '<span class="tsocLv__count" title="Etapas cumplidas de las que aplican en este caso">' + ok + ' de ' + applies + ' etapas</span>' +
      (p.total != null ? '<b class="tsocLv__total" title="Tiempo total hasta el último paso medido">' + esc(fmtMs(p.total)) + '</b>' : '') + '</div>' +
      '<ol class="tsocLv__steps">' + items.map(function (s, i) {
        return '<li class="tsocLv__step tsocLv__step--' + esc(s.key) + ' is-' + s.state + '" style="--i:' + i + '" aria-label="' + esc(s.title + ': ' + MARK_ES[s.state]) + '">' +
          '<span class="tsocLv__t">' + (s.t == null ? (s.state === 'run' ? 'en curso' : s.state === 'hold' ? 'en espera' : '') : '+' + esc(fmtMs(s.t))) + '</span>' +
          '<i class="tsocLv__dot">' + MARK[s.state] + '</i><div class="tsocLv__txt"><b>' + esc(s.title) + '</b><small>' + esc(s.detail) + '</small></div></li>';
      }).join('') + '</ol>' +
      (opt.compact || !(p.chips || []).length ? '' : '<div class="tsocLv__chips">' + p.chips.map(function (c) { return '<span>' + esc(c) + '</span>'; }).join('') + '</div>') + '</div>';
  }

  // Respuesta inmediata (traza del carril rápido) → etapas.
  function tracePipe(t) {
    var st = TRACE_STATE[t.status] || [t.status, 'muted'], dev = t.device || {}, by = {}, young = Date.now() - Date.parse(t.at) < 120000, first = true;
    (t.steps || []).forEach(function (s) { by[s.key] = s; });
    var items = STAGES.map(function (d) {
      var s = by[d[0]], k = d[0];
      if (s) {
        var bad = t.status === 'failed' && (k === 'verify' || (k === 'act' && !by.verify));
        return { key: k, state: bad ? 'fail' : 'done', title: s.title, detail: s.detail, t: s.t_ms };
      }
      var state = 'skip', detail = 'No aplica en este caso';
      if (t.status === 'running') { state = first ? 'run' : 'todo'; detail = d[2]; }
      else if (t.status === 'waiting') { state = k === 'act' ? 'hold' : 'todo'; detail = k === 'act' ? 'Espera la aprobación de una persona' : d[2]; }
      else if (t.status === 'sent' || t.status === 'verified') {
        if (!young) detail = k === 'verify' ? 'El equipo no confirmó a tiempo' : 'No se registró';
        else if (k === 'verify') { state = 'run'; detail = 'Esperando la confirmación del equipo'; }
        else { state = by.verify ? 'run' : 'todo'; detail = by.verify ? 'Redactando el informe' : d[2]; }
      }
      first = false;
      return { key: k, state: state, title: d[1], detail: detail, t: null };
    });
    return { tone: st[1], state: st[0], host: ((t.agent && t.agent.name) || '') + (dev.name ? ' · ' + dev.name : ''), total: t.total_ms, items: items,
      chips: [t.rule && t.rule.id ? 'Regla ' + t.rule.id : '', dev.vid ? 'VID ' + dev.vid + ' · PID ' + dev.pid : '', dev.serial ? 'Serie ' + dev.serial : '',
        t.incident_id || t.trace_id].filter(Boolean) };
  }
  function traceHtml(t, opt) { return pipeHtml(tracePipe(t), opt); }

  // Sin respuestas todavía: el mismo pipeline, en reposo, para que se vea qué etapas recorrerá.
  function idleHtml(opt) {
    return pipeHtml({ tone: 'muted', state: 'En reposo · listo para la próxima señal', host: '', total: null,
      items: STAGES.map(function (d) { return { key: d[0], state: 'todo', title: d[1], detail: d[2], t: null }; }) }, opt);
  }

  // Respuesta que pasa por una persona (aprobar) o cambio que se deshace → etapas, a partir del documento de respuesta.
  function isUndo(r) { return /^(undo_requested|undoing|undone|undo_failed)$/.test(r.status); }
  function respPipe(r) {
    var host = (r.agent && r.agent.name) || '', s = r.status, items;
    if (isUndo(r)) {
      var sent = s === 'undone', bad = s === 'undo_failed';
      items = [
        { key: 'ask', state: 'done', title: 'Petición de deshacer', detail: 'La pidió ' + (r.undo_by || 'una persona') + ' desde el panel' },
        { key: 'act', state: sent ? 'done' : bad ? 'fail' : 'run', title: sent ? 'Orden enviada al equipo' : bad ? 'No se pudo enviar la orden' : 'Enviando la orden al equipo',
          detail: bad ? (r.exec_result || 'El equipo no respondió') : 'Se retira: ' + (r.action_label || r.action || 'la acción') },
        { key: 'verify', state: sent ? 'done' : bad ? 'skip' : 'todo', title: 'Cambio deshecho', detail: sent ? 'El equipo vuelve a su estado anterior' : bad ? 'El cambio sigue aplicado' : 'Pendiente' }];
      return { tone: sent ? 'undo' : bad ? 'bad' : 'undo', state: sent ? 'Cambio deshecho' : bad ? 'No se pudo deshacer' : 'Deshaciendo los cambios', host: host, total: null, items: items, chips: [r.incident_id] };
    }
    var wait = s === 'recommended', run = s === 'approved' || s === 'executing', done = s === 'executed', fail = s === 'failed';
    items = [
      { key: 'detect', state: 'done', title: 'Amenaza detectada', detail: r.title || 'Incidente ' + r.incident_id },
      { key: 'decide', state: 'done', title: 'Analizada', detail: 'Recomendación: ' + (r.action_label || r.action || '') + (r.confidence != null ? ' · confianza ' + r.confidence : '') },
      { key: 'approve', state: wait ? 'hold' : 'done', title: wait ? 'Aprobación' : r.auto ? 'Aprobada por la política' : 'Aprobada',
        detail: wait ? 'Espera tu decisión: Permitir o Denegar' : r.auto ? 'Modo automático' : 'Por ' + (r.decided_by || 'una persona') },
      { key: 'act', state: done ? 'done' : fail ? 'fail' : run ? 'run' : 'todo', title: done ? 'Orden enviada al equipo' : fail ? 'No se pudo actuar' : 'Acción en el equipo',
        detail: fail ? (r.exec_result || '') : run ? 'El servicio la está ejecutando' : done ? (r.action_label || '') : 'Pendiente de aprobación' },
      { key: 'explain', state: r.story && (done || fail) ? 'done' : done || fail ? 'run' : 'todo', title: 'Informe', detail: 'Historia sencilla y aviso al canal' }];
    return { tone: done ? 'ok' : fail ? 'bad' : wait ? 'warn' : 'bad', state: done ? 'Amenaza contenida' : fail ? 'No se pudo actuar' : wait ? 'Espera tu aprobación' : 'Respondiendo a la amenaza',
      host: host, total: done && r.response_ms != null ? r.response_ms : null, items: items, chips: [r.incident_id] };
  }
  function traceRow(t, when) {
    var st = TRACE_STATE[t.status] || [t.status, 'muted'], dev = t.device || {};
    return '<li class="tsocLv__row tsocLv--' + st[1] + '"><span class="tsocLv__state"><i></i>' + esc(st[0]) + '</span>' +
      '<span class="tsocLv__host">' + esc((t.agent && t.agent.name) || '') + (dev.name ? ' · ' + esc(dev.name) : '') + '</span>' +
      '<span class="tsocLv__when">' + esc(when || '') + '</span><b class="tsocLv__total">' + esc(fmtMs(t.total_ms)) + '</b></li>';
  }

  // ---------------------------------------------------------------- isla (siempre visible, arriba al centro)
  // Resume en una línea lo que hace el Guardian ahora mismo y se despliega sola cuando pasa algo:
  // la traza de una respuesta, o una acción que espera a una persona, con Permitir / Denegar ahí mismo.
  // La pestaña "Técnico" enseña lo mismo sin adornos: identificadores, orden enviada, tiempos y el JSON.
  var LV = { at: 0, recAt: 0, trace: null, pulse: null, pending: null, active: null, done: null, sig: null, tone: null, open: false, tab: 'sum', key: null, until: 0, busy: false, note: null };
  var island = null;

  function pollLive() {
    LV.at = Date.now();
    search(IDX, { size: 4, sort: [{ at: { order: 'desc', unmapped_type: 'date' } }], query: { bool: { minimum_should_match: 1, should: [
      { ids: { values: ['pulse'] } }, { bool: { filter: [{ term: { kind: 'trace' } }, { range: { at: { gte: 'now-24h' } } }] } }] } } }).then(function (r) {
      if (!r) return;
      var docs = r.hits.hits.map(function (h) { return h._source; });
      LV.pulse = docs.filter(function (d) { return d.kind === 'pulse'; })[0] || null;
      var t = docs.filter(function (d) { return d.kind === 'trace'; })[0] || null;
      LV.trace = t;
      if (t && Date.now() - Date.parse(t.at) < 120000) {
        var before = sstore('lv.' + t.trace_id);
        if (before !== t.status) {
          sstore('lv.' + t.trace_id, t.status);
          // Algo acaba de pasar: la isla se abre sola medio minuto y el robot lo cuenta.
          LV.open = true; LV.until = Date.now() + 30000; LV.replay = !before; LV.key = null;
          var host = (t.agent && t.agent.name) || 'un equipo', acted = t.status === 'sent' || t.status === 'verified';
          var what = t.action === 'block_usb_phone' ? 'un teléfono' : t.device && t.device.kind === 'input' ? 'un ratón o teclado USB' : 'un almacenamiento USB';
          var say = acted ? 'Acabo de bloquear ' + what + ' no autorizado en ' + host + ' en ' + fmtMs(t.total_ms).replace(' ms', ' milisegundos').replace(' s', ' segundos') + '.'
            : t.status === 'waiting' ? 'Detecté ' + what + ' no autorizado en ' + host + '. Espero la decisión de una persona.' : null;
          if (!before && say) { speak(say); if (A.open) addMsg('bot', say, ['open_guardian']); }
        }
      }
      syncState(); paintIsland();
    });
    if (Date.now() - LV.recAt > 4000) {
      LV.recAt = Date.now();
      // Una sola búsqueda para lo que pasa por el camino normal:
      //   pending = espera a una persona (modo manual, última media hora) · active = se está ejecutando o deshaciendo
      //   done = acaba de terminar (últimos 3 min): acción aplicada, cambio deshecho o deshacer fallido.
      search(RESP, { size: 8, sort: [{ updated_at: 'desc' }], query: { bool: { minimum_should_match: 1, should: [
        { bool: { filter: [{ term: { status: 'recommended' } }, { term: { mode: 'approve' } }, { range: { updated_at: { gte: 'now-30m' } } }],
          must_not: [{ term: { action: 'manual_review' } }] } },
        { terms: { status: ['approved', 'executing', 'undo_requested', 'undoing'] } },
        { bool: { filter: [{ term: { status: 'executed' } }, { range: { executed_at: { gte: 'now-3m' } } }] } },
        { bool: { filter: [{ term: { status: 'undone' } }, { range: { undone_at: { gte: 'now-3m' } } }] } },
        { bool: { filter: [{ term: { status: 'undo_failed' } }, { range: { updated_at: { gte: 'now-3m' } } }] } }] } } }).then(function (r) {
        if (!r) return;
        var docs = r.hits.hits.map(function (h) { return h._source; });
        var pick = function (re) { return docs.filter(function (d) { return re.test(d.status); })[0] || null; };
        var p = pick(/^recommended$/), a = pick(/^(approved|executing|undo_requested|undoing)$/), d = pick(/^(executed|undone|undo_failed)$/);
        if (d) d.done_at = d.status === 'undone' ? d.undone_at : d.status === 'executed' ? d.executed_at : d.updated_at;
        if (p && (!LV.pending || LV.pending.incident_id !== p.incident_id) && !sstore('pd.' + p.incident_id)) {
          sstore('pd.' + p.incident_id, '1'); LV.open = true; LV.tab = 'sum'; LV.until = Date.now() + 60000;
        }
        // Un cambio que se deshace (o una acción aprobada que termina): se abre para que se vea cada etapa, y se dice tal cual.
        var ev = a || d, sig = ev && ev.incident_id + '|' + ev.status;
        if (ev && (isUndo(ev) || a || !ev.reflex) && sstore('rs.' + ev.incident_id) !== ev.status) {
          var known = sstore('rs.' + ev.incident_id) != null || LV.sig != null;
          sstore('rs.' + ev.incident_id, ev.status);
          if (known || a) {
            LV.open = true; LV.tab = 'sum'; LV.until = Date.now() + 30000; LV.key = null;
            var host = (ev.agent && ev.agent.name) || 'un equipo';
            var say = ev.status === 'undone' ? 'Cambio deshecho en ' + host + '. Retiré la acción ' + (ev.action_label ? '«' + ev.action_label + '»' : '') + ' porque ' + (ev.undo_by || 'una persona') + ' lo pidió.'
              : ev.status === 'undo_failed' ? 'No pude deshacer el cambio en ' + host + '. El cambio sigue aplicado.'
                : ev.status === 'executed' ? 'Amenaza contenida en ' + host + '.' : null;
            if (say) { speak(say); if (A.open) addMsg('bot', say, ['open_guardian']); }
          }
        }
        LV.sig = sig || '';
        LV.pending = p; LV.active = a; LV.done = d;
        syncState(); paintIsland();
      });
      // La alerta crítica del agente (nivel 12 o más) pone la isla en rojo en el momento, sin esperar al incidente.
      search('triplesoc-alerts-*', { size: 1, sort: [{ timestamp: 'desc' }], _source: ['timestamp', 'agent.name', 'rule.description', 'rule.level'],
        query: { bool: { filter: [{ range: { 'rule.level': { gte: 12 } } }, { range: { timestamp: { gte: 'now-3m' } } }] } } }).then(function (r) {
        if (!r) return;
        var h = r.hits.hits[0] && r.hits.hits[0]._source;
        var was = LV.alert && LV.alert.at;
        LV.alert = h ? { at: h.timestamp, host: (h.agent && h.agent.name) || 'un equipo',
          what: String((h.rule && h.rule.description) || 'alerta crítica').replace(/^TripleSOC Security:\s*/, '') } : null;
        if (LV.alert && LV.alert.at !== was && !sstore('al.' + LV.alert.at)) {
          sstore('al.' + LV.alert.at, '1'); LV.open = true; LV.until = Date.now() + 30000; LV.key = null;
        }
        syncState(); paintIsland();
      });
    }
  }

  // Qué color y qué frase lleva la isla. Rojo = hay una amenaza y aún no está resuelta. Verde lleno = se acaba de
  // resolver con un cambio real. Azul = se está deshaciendo (o se deshizo) un cambio a petición de una persona.
  function situation() {
    var p = LV.pulse, t = LV.trace, pd = LV.pending, a = LV.active, d = LV.done, v = A.vuln;
    var fresh = p && Date.now() - Date.parse(p.at) < 20000, on = fresh && p.lane === 'online';
    var host = function (x) { return (x && x.agent && x.agent.name) || 'un equipo'; };
    var age = function (iso) { return Date.now() - Date.parse(iso); };
    var tr = t && age(t.at) < 120000 ? t : null, dn = d && age(d.done_at || d.updated_at) < 120000 ? d : null;
    if (a && isUndo(a)) return { tone: 'undo', icon: 'undo', line: 'Deshaciendo los cambios · ' + host(a) };
    if (a) return { tone: 'danger', icon: 'alert', line: 'Amenaza detectada · respondiendo · ' + host(a) };
    if (pd) return { tone: 'danger', icon: 'alert', line: 'Amenaza detectada · espera tu aprobación · ' + host(pd) };
    // Lo último que pasó manda: si después de contener se deshizo, se dice "deshecho", no "contenido".
    if (dn && isUndo(dn) && (!tr || Date.parse(dn.done_at || dn.updated_at) >= Date.parse(tr.at)))
      return dn.status === 'undone' ? { tone: 'undo', icon: 'undo', line: 'Cambio deshecho · ' + host(dn) }
        : { tone: 'danger', icon: 'alert', line: 'No se pudo deshacer el cambio · ' + host(dn) };
    if (tr) {
      if (tr.status === 'sent' || tr.status === 'verified')
        return { tone: 'safe', icon: 'check', line: 'Amenaza contenida · ' + host(tr) + (tr.total_ms != null ? ' · ' + fmtMs(tr.total_ms) : '') };
      if (tr.status === 'running') return { tone: 'danger', icon: 'alert', line: 'Amenaza detectada · respondiendo · ' + host(tr) };
      if (tr.status === 'waiting') return { tone: 'danger', icon: 'alert', line: 'Amenaza detectada · espera a una persona · ' + host(tr) };
      if (tr.status === 'failed') return { tone: 'danger', icon: 'alert', line: 'No se pudo contener · ' + host(tr) };
      if (tr.status === 'allowed') return { tone: 'ok', icon: '', line: 'Dispositivo autorizado · ' + host(tr) };
    }
    if (dn && dn.status === 'executed') return { tone: 'safe', icon: 'check', line: 'Amenaza contenida · ' + host(dn) };
    // Una alerta que ya respondió el Guardian (contenida, autorizada o deshecha después) no vuelve a poner la isla en rojo.
    var handled = LV.alert && ((t && /^(sent|verified|allowed)$/.test(t.status) && Date.parse(t.at) >= Date.parse(LV.alert.at) - 15000) ||
      (d && Date.parse(d.done_at || d.updated_at) >= Date.parse(LV.alert.at)));
    if (LV.alert && !handled && age(LV.alert.at) < 180000) return { tone: 'danger', icon: 'alert', line: 'Alerta crítica · ' + LV.alert.host + ' · ' + LV.alert.what };
    if (A.threats) return { tone: 'danger', icon: 'alert', line: A.threats === 1 ? 'Amenaza sin contener · 1 incidente abierto' : 'Amenazas sin contener · ' + A.threats + ' incidentes abiertos' };
    if (v && !v.solved) return { tone: 'danger', icon: 'alert', line: 'Vulnerabilidad crítica · ' + v.host + (v.cve ? ' · ' + v.cve : '') };
    if (v && v.solved && age(v.at) < 180000) return { tone: 'safe', icon: 'check', line: 'Vulnerabilidad corregida · ' + v.host + (v.cve ? ' · ' + v.cve : '') };
    if (on) return { tone: 'ok', icon: '', line: 'Vigilando · ' + (p.events_1m || 0) + ' eventos/min' };
    return { tone: 'muted', icon: '', line: 'Sin señal del servicio' };
  }
  var IS_ICON = {
    alert: '<svg class="tsocIs__ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3.5 2.8 19.5h18.4z"/><path d="M12 10v4.5M12 17.2v.3"/></svg>',
    check: '<svg class="tsocIs__ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m8.5 12 2.5 2.5 4.5-5"/></svg>',
    undo: '<svg class="tsocIs__ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 8H4V4"/><path d="M4.5 8A8.5 8.5 0 1 1 3.6 13"/></svg>' };

  function decideFromIsland(status) {
    var p = LV.pending;
    if (!p || LV.busy) return;
    if (status === 'approved' && !window.confirm('¿Permitir "' + p.action_label + '" en ' + ((p.agent && p.agent.name) || 'el equipo') + '?\n\nSe ejecutará en el equipo ahora. Se puede deshacer después.')) return;
    LV.busy = true; LV.note = null; LV.key = null; paintIsland();
    proxy(RESP + '/_update/' + encodeURIComponent(p.incident_id) + '?refresh=wait_for', 'POST',
      { doc: { status: status, decided_by: A.user || 'analyst', decided_at: new Date().toISOString() } })
      .then(function (r) {
        if (!r.ok) throw new Error(r.status === 403 ? 'Tu usuario no tiene permiso para decidir respuestas.' : 'No se pudo guardar (HTTP ' + r.status + ').');
        LV.note = status === 'approved' ? 'Permitido. El servicio lo ejecuta en su siguiente pasada.' : 'Denegado. No se ejecuta nada.';
        LV.pending = null; LV.recAt = 0;
      }).catch(function (e) { LV.note = e.message; })
      .then(function () { LV.busy = false; LV.key = null; LV.until = Date.now() + 12000; paintIsland(); });
  }

  function techHtml() {
    var t = LV.trace, p = LV.pulse, rows = [];
    function row(k, v) { if (v != null && v !== '') rows.push('<tr><th>' + esc(k) + '</th><td>' + esc(v) + '</td></tr>'); }
    if (p) {
      row('servicio', 'triplesoc-responder ' + (p.version || '') + ' · carril ' + p.lane + ' · ' + (p.armed ? 'armado' : 'sin ejecución'));
      row('modo', p.mode); row('eventos leídos', (p.events_total || 0) + ' desde el arranque · ' + (p.events_1m || 0) + ' en el último minuto');
      row('señales atendidas', p.signals_total); row('retraso de lectura', p.read_lag_ms != null ? p.read_lag_ms + ' ms' : null);
      row('último evento', p.last_event_at); row('pulso', p.at);
    }
    var html = '<table class="tsocIs__kv">' + rows.join('') + '</table>';
    if (t) {
      rows = [];
      row('traza', t.trace_id); row('incidente', t.incident_id); row('alerta', t.alert_id);
      row('regla', t.rule && (t.rule.id + ' · ' + t.rule.description)); row('agente', t.agent && (t.agent.id + ' · ' + t.agent.name + ' · ' + (t.agent.ip || '')));
      row('dispositivo', t.device && [t.device.name, t.device.vid && ('VID_' + t.device.vid + '&PID_' + t.device.pid), t.device.serial].filter(Boolean).join(' · '));
      row('acción', t.action); if (t.command) { row('llamada', t.command.api); row('script en el equipo', t.command.script); row('ejecuta', t.command.runs); } row('estado', t.status); row('reloj equipo/servidor', t.clock_synced ? 'coherente' : 'desfasado (tiempos desde la detección)');
      html += '<div class="tsocIs__sub">Última respuesta</div><table class="tsocIs__kv">' + rows.join('') + '</table>' +
        '<pre class="tsocIs__log">' + (t.steps || []).map(function (s) {
          var ms = s.t_ms == null ? '—' : '+' + s.t_ms + ' ms';
          return esc((s.at || '').replace('T', ' ').replace('Z', '') + '  ' + ('         ' + ms).slice(-9) + '  ' + (s.key + '        ').slice(0, 8) + ' ' + s.detail);
        }).join('\n') + '</pre>' +
        '<details class="tsocIs__json"><summary>Documento completo (JSON)</summary><pre>' + esc(JSON.stringify(t, null, 1)) + '</pre></details>';
    } else html += '<div class="tsocIs__sub">Sin respuestas en las últimas 24 h</div>';
    return html;
  }

  // Ocultar o mostrar el robot de abajo (se recuerda en este navegador). La isla y Alt+G siguen funcionando.
  function setRobot(show) {
    A.hidden = !show; store('robot', show ? 'on' : 'off');
    if (!show) { A.open = false; try { speechSynthesis.cancel(); } catch (x) {} if (root) root.querySelector('[data-as-bubble]').hidden = true; }
    paint(); LV.key = null; paintIsland();
  }

  // Actividad real del servicio, tal como la publica en su pulso: cada alerta que evalúa y cada cosa que hace.
  var FEED_TAG = { alert: 'alerta', signal: 'señal', act: 'acción', cmd: 'comando', svc: 'servicio', chat: 'chat', warn: 'aviso' };
  function liveHtml() {
    var p = LV.pulse, fresh = p && Date.now() - Date.parse(p.at) < 20000, feed = (p && p.activity) || [];
    if (!fresh) return '<div class="tsocIs__sub">Sin señal del servicio: no hay actividad que mostrar.</div>';
    return '<div class="tsocIs__liveHead"><i></i>En directo · ' + esc(p.events_1m || 0) + ' alertas evaluadas en el último minuto · ' + esc(p.events_total || 0) + ' desde el arranque</div>' +
      '<div class="tsocIs__feed">' + (feed.length ? feed.slice().reverse().map(function (f) {
        return '<div class="tsocIs__ev tsocIs__ev--' + esc(f.kind) + '"><time>' + esc(String(f.at || '').slice(11, 19)) + '</time><em>' + esc(FEED_TAG[f.kind] || f.kind) + '</em><span>' + esc(f.text) + (f.n > 1 ? ' <b>×' + esc(f.n) + '</b>' : '') + '</span></div>';
      }).join('') : '<div class="tsocIs__sub">Vigilando. Todavía no ha llegado ninguna alerta desde que arrancó el servicio.</div>') + '</div>' +
      '<div class="tsocIs__liveFoot">Horas en UTC · se actualiza cada 2 s · alertas evaluadas y comandos internos, sin resumir</div>';
  }

  function paintIsland() {
    if (!island) return;
    var p = LV.pulse, t = LV.trace, pd = LV.pending;
    var fresh = p && Date.now() - Date.parse(p.at) < 20000;
    if (LV.open && LV.until && Date.now() > LV.until && !island.matches(':hover') && !pd) { LV.open = false; LV.until = 0; }
    var sit = situation(), tone = sit.tone, line = sit.line, act = LV.active, dn = LV.done;
    var where = window.TSOCNav && window.TSOCNav.here ? window.TSOCNav.here() : null;
    // Lo que se enseña como pipeline del camino normal: lo que está en curso o, si acaba de terminar, un deshacer.
    var flow = act || (dn && isUndo(dn) && Date.now() - Date.parse(dn.updated_at) < 120000 ? dn : null);
    var mode = p && fresh ? (p.mode === 'auto' ? (p.armed ? 'AUTO' : 'AUTO · sin ejecución') : 'MANUAL') : '';
    var key = JSON.stringify([LV.open, LV.tab, tone, line, mode, t && t.trace_id + t.status + (t.steps || []).length, pd && pd.incident_id, LV.busy, LV.note,
      LV.open && LV.tab !== 'sum' && p && p.at, A.hidden, where && where.label, flow && flow.incident_id + flow.status]);
    if (key === LV.key) return;
    // En la pestaña técnica solo se refrescan los datos si el lector no tiene abierto el JSON.
    if (LV.key && LV.open && LV.tab === 'tech' && island.querySelector('details[open]') && JSON.parse(LV.key).slice(0, 9).join() === JSON.parse(key).slice(0, 9).join()) return;
    LV.key = key;
    // El paso de rojo a verde (amenaza resuelta) se marca con un barrido, para que se note que algo cambió.
    var flip = LV.tone === 'danger' && tone === 'safe';
    LV.tone = tone;
    island.className = 'tsocIs tsocIs--' + tone + (LV.open ? ' is-open' : '') + (flip ? ' is-flip' : '');
    var body = '';
    if (LV.open) {
      body = '<div class="tsocIs__body">' +
        (where ? '<div class="tsocIs__here">' + window.TSOCNav.svg(where.icon) + '<span>Estás en <b>' + esc(where.label) + '</b> · ' + esc(where.does) + '</span></div>' : '') +
        '<div class="tsocIs__tabs"><button class="' + (LV.tab === 'sum' ? 'is-on' : '') + '" data-is="tab-sum">Resumen</button>' +
        '<button class="' + (LV.tab === 'live' ? 'is-on' : '') + '" data-is="tab-live">En vivo</button>' +
        '<button class="' + (LV.tab === 'tech' ? 'is-on' : '') + '" data-is="tab-tech">Técnico</button>' +
        '<span class="tsocIs__tools"><button data-is="chat" title="Abrir la conversación (Alt+G)">Hablar</button><button data-is="robot">' + (A.hidden ? 'Mostrar robot' : 'Ocultar robot') + '</button></span>' +
        '<a data-is="go" href="/app/dashboards#/view/triplesoc-guardian">Centro de mando</a></div>';
      if (LV.tab === 'tech') body += techHtml();
      else if (LV.tab === 'live') body += liveHtml();
      else {
        if (pd) body += '<div class="tsocIs__ask"><div class="tsocIs__askTxt"><b>' + esc(pd.action_label) + '</b><span>' + esc((pd.agent && pd.agent.name) || '') + ' · ' + esc(pd.incident_id) +
          ' · riesgo ' + esc(pd.risk) + ' · confianza ' + esc(pd.confidence) + '</span><p>' + esc(pd.reason) + '</p></div>' +
          '<div class="tsocIs__askBtns"><button class="tsocIs__deny" data-is="deny"' + (LV.busy ? ' disabled' : '') + '>Denegar</button>' +
          '<button class="tsocIs__allow" data-is="allow"' + (LV.busy ? ' disabled' : '') + '>Permitir</button></div></div>';
        if (LV.note) body += '<div class="tsocIs__note">' + esc(LV.note) + '</div>';
        if (pd) body += pipeHtml(respPipe(pd), { compact: true });
        if (flow) body += pipeHtml(respPipe(flow), { compact: true });
        if (t && !(flow && isUndo(flow))) body += traceHtml(t, { compact: true, replay: LV.replay });
        else if (!t && !pd && !flow) body += '<div class="tsocIs__sub">Todo tranquilo. Estas son las etapas que verás marcarse cuando el Guardian actúe:</div>' + idleHtml({ compact: true });
        LV.replay = false;
      }
      body += '</div>';
    }
    island.innerHTML = '<button class="tsocIs__pill" data-is="toggle" aria-expanded="' + LV.open + '" title="Guardian en directo">' +
      (where ? '<span class="tsocIs__where" title="' + esc(where.label + ' — ' + where.does) + '">' + window.TSOCNav.svg(where.icon) + esc(where.label) + '</span>' : '') +
      (IS_ICON[sit.icon] || '<i class="tsocIs__dot"></i>') + '<b>Guardian</b><span class="tsocIs__line">' + esc(line) + '</span>' +
      (mode ? '<em class="tsocIs__mode">' + esc(mode) + '</em>' : '') + '<span class="tsocIs__chev">▾</span></button>' + body;
  }

  function onIsland(e) {
    var x = e.target.closest('[data-is]');
    if (!x) return;
    var a = x.getAttribute('data-is');
    if (a === 'toggle') { LV.open = !LV.open; LV.until = 0; LV.note = null; }
    if (a === 'tab-sum') LV.tab = 'sum';
    if (a === 'tab-tech') { LV.tab = 'tech'; LV.until = 0; }
    if (a === 'tab-live') { LV.tab = 'live'; LV.until = 0; }
    if (a === 'chat') { LV.open = false; LV.key = null; paintIsland(); openPanel(); return; }
    if (a === 'robot') { setRobot(A.hidden); return; }
    if (a === 'go') {
      if (e.button !== 0 || e.ctrlKey || e.metaKey || e.shiftKey) return;
      e.preventDefault(); LV.open = false; history.pushState(null, '', x.getAttribute('href')); window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
    }
    if (a === 'allow') { decideFromIsland('approved'); return; }
    if (a === 'deny') { decideFromIsland('rejected'); return; }
    LV.key = null; paintIsland();
  }

  function mountIsland() {
    if (island) { if (!island.isConnected) document.body.appendChild(island); placeIsland(); return; }
    island = document.createElement('div');
    island.id = 'tsoc-island'; island.className = 'tsocIs';
    island.addEventListener('click', onIsland);
    document.body.appendChild(island);
    placeIsland();
    paintIsland();
  }

  // Cuelga justo debajo de la cabecera (como una muesca), para no tapar sus botones.
  function placeIsland() {
    var host = document.querySelector('.app-wrapper') || document.querySelector('#app-wrapper');
    island.style.top = (host ? Math.max(0, Math.round(host.getBoundingClientRect().top)) : 48) + 'px';
  }

  function mount() {
    if (root) return;
    root = document.createElement('div');
    root.id = 'tsoc-assistant';
    root.className = 'tsocAs';
    root.innerHTML =
      '<div class="tsocAs__bubble" data-as-bubble hidden></div>' +
      '<section class="tsocAs__panel" data-as-panel aria-label="Guardian" hidden>' +
      '<header class="tsocAs__head"><div class="tsocAs__headBot">' + bot('tsocAs__bot--mini') + '</div>' +
      '<div class="tsocAs__headText"><b>Guardian</b><span data-as-status></span></div>' +
      '<button class="tsocAs__icon" data-as="sound" title="Voz"></button><button class="tsocAs__icon" data-as="close" title="Cerrar (Esc)">✕</button></header>' +
      '<div class="tsocAs__msgs" data-as-msgs></div>' +
      '<div class="tsocAs__chips" data-as-chips></div>' +
      '<form class="tsocAs__input" data-as-form><button type="button" class="tsocAs__mic" data-as="mic" title="Hablar"><span></span></button>' +
      '<input data-as-input maxlength="1000" placeholder="Pregúntame lo que quieras…" autocomplete="off">' +
      '<button type="submit" class="tsocAs__send" title="Enviar">➤</button></form>' +
      '<footer class="tsocAs__foot">Solo leo datos y te sugiero acciones · nada cambia sin tu confirmación</footer></section>' +
      '<button class="tsocAs__launcher" data-as="toggle" aria-label="Hablar con Guardian (Alt+G)">' + bot('tsocAs__bot--orb') +
      '<i class="tsocAs__ring"></i><i class="tsocAs__ring tsocAs__ring--2"></i><b class="tsocAs__badge" data-as-badge hidden></b></button>' +
      '<button class="tsocAs__hide" data-as="hide" title="Ocultar el robot (vuelve desde la isla de arriba)" aria-label="Ocultar el robot">✕</button>';
    root.addEventListener('click', onClick);
    root.querySelector('[data-as-form]').addEventListener('submit', function (e) { e.preventDefault(); ask(root.querySelector('[data-as-input]').value); });
    document.body.appendChild(root);
    paint(true);
  }

  function msgHtml(m) {
    var sug = (m.suggest || []).map(function (s) { return LABELS[s] ? '<button class="tsocAs__sug" data-sug="' + esc(s) + '">' + esc(LABELS[s]) + '</button>' : ''; }).join('');
    return '<div class="tsocAs__msg tsocAs__msg--' + m.who + '">' + (m.who === 'bot' ? '<div class="tsocAs__msgBot">' + bot('tsocAs__bot--tiny') + '</div>' : '') +
      '<div class="tsocAs__msgBody"><p>' + esc(m.text) + '</p>' + (sug ? '<div class="tsocAs__sugs">' + sug + '</div>' : '') + '</div></div>';
  }

  function paint(scroll) {
    if (!root) return;
    var st = A.listening ? 'listening' : A.thinking ? 'thinking' : A.speaking ? 'speaking' : A.state;
    root.setAttribute('data-state', st);
    root.classList.toggle('is-open', A.open);
    root.classList.toggle('is-hidden', A.hidden);
    var panel = root.querySelector('[data-as-panel]'); panel.hidden = !A.open;
    var label = { idle: 'En línea · vigilando', thinking: 'Pensando…', speaking: 'Hablando…', listening: 'Te escucho…',
      alert: 'Atento · amenaza sin contener', safe: 'Protegido · amenaza contenida', defending: 'Defendiendo un equipo', undoing: 'Deshaciendo los cambios' }[st];
    root.querySelector('[data-as-status]').innerHTML = '<i></i>' + esc(label) + (A.mode ? ' · modo ' + (A.mode === 'auto' ? 'automático' : 'manual') : '');
    root.querySelector('[data-as="sound"]').textContent = A.sound ? '🔊' : '🔇';
    var badge = root.querySelector('[data-as-badge]'); badge.hidden = !A.unread || A.open; badge.textContent = A.unread;
    var box = root.querySelector('[data-as-msgs]');
    var html = A.msgs.map(msgHtml).join('') + (A.thinking ? '<div class="tsocAs__msg tsocAs__msg--bot"><div class="tsocAs__msgBot">' + bot('tsocAs__bot--tiny') + '</div><div class="tsocAs__msgBody tsocAs__dots"><i></i><i></i><i></i></div></div>' : '');
    if (box.getAttribute('data-n') !== String(html.length)) { box.innerHTML = html; box.setAttribute('data-n', html.length); if (scroll !== false) box.scrollTop = box.scrollHeight; }
    var chips = root.querySelector('[data-as-chips]');
    var list = CHIPS.slice(); if (A.mode === 'manual') list.push('Activa el modo automático');
    var ch = list.map(function (c) { return '<button class="tsocAs__chip" data-chip="' + esc(c) + '">' + esc(c) + '</button>'; }).join('');
    if (chips.getAttribute('data-k') !== ch) { chips.innerHTML = ch; chips.setAttribute('data-k', ch); }
    chips.hidden = A.thinking;
  }

  function bubble(text, actions, ms) {
    if (!root || A.open || A.hidden) return;
    var b = root.querySelector('[data-as-bubble]');
    b.innerHTML = '<button class="tsocAs__bx" data-as="bubble-close" aria-label="Cerrar">✕</button><p>' + esc(text) + '</p>' +
      ((actions || []).length ? '<div class="tsocAs__sugs">' + actions.map(function (a) { return '<button class="tsocAs__sug" data-bub="' + esc(a[0]) + '">' + esc(a[1]) + '</button>'; }).join('') + '</div>' : '');
    b.hidden = false; b.classList.remove('is-in', 'tsocAs__bubble--live'); void b.offsetWidth; b.classList.add('is-in');
    clearTimeout(bubbleTimer); bubbleTimer = setTimeout(function () { b.hidden = true; }, ms || 14000);
  }

  function openPanel(withGreeting) {
    A.open = true; A.unread = 0;
    root.querySelector('[data-as-bubble]').hidden = true;
    if (!A.msgs.length || withGreeting) {
      var sec = section();
      var hi = '¡Hola' + (A.user && A.user !== 'analyst' ? ', ' + A.user : '') + '! Soy Guardian, el robot que protege tus equipos. ' +
        (sec ? 'Ahora estás en ' + sec.name + '. ' + sec.say : 'Pregúntame lo que quieras sobre la seguridad de tu empresa.');
      addMsg('bot', hi, ['open_guardian']); speak(hi);
    }
    paint();
    setTimeout(function () { var i = root.querySelector('[data-as-input]'); if (i) i.focus(); }, 60);
  }

  function onClick(e) {
    var t = e.target.closest('[data-as],[data-sug],[data-chip],[data-bub]');
    if (!t) return;
    if (t.hasAttribute('data-sug')) { doSuggest(t.getAttribute('data-sug')); return; }
    if (t.hasAttribute('data-chip')) { ask(t.getAttribute('data-chip')); return; }
    if (t.hasAttribute('data-bub')) {
      var code = t.getAttribute('data-bub');
      root.querySelector('[data-as-bubble]').hidden = true;
      if (code === 'more') { openPanel(); ask('Explícame esta pantalla con más detalle'); }
      else if (code === 'hello') { openPanel(true); }
      else doSuggest(code);
      return;
    }
    var a = t.getAttribute('data-as');
    if (a === 'toggle') { if (A.open) { A.open = false; paint(); } else openPanel(); }
    if (a === 'close') { A.open = false; try { speechSynthesis.cancel(); } catch (x) {} paint(); }
    if (a === 'sound') { A.sound = !A.sound; store('sound', A.sound ? 'on' : 'off'); if (!A.sound) try { speechSynthesis.cancel(); } catch (x) {} paint(); }
    if (a === 'mic') listen();
    if (a === 'bubble-close') root.querySelector('[data-as-bubble]').hidden = true;
    if (a === 'hide') setRobot(false);
  }

  // Los ojos siguen al ratón (máx. 3 px).
  document.addEventListener('mousemove', function (e) {
    if (!root) return;
    var eyes = document.querySelectorAll('.tsocAs__eyes, .tsocGd__eyes');
    for (var i = 0; i < eyes.length; i++) {
      var r = eyes[i].getBoundingClientRect(); if (!r.width) continue;
      var dx = e.clientX - (r.left + r.width / 2), dy = e.clientY - (r.top + r.height / 2), d = Math.max(1, Math.hypot(dx, dy));
      eyes[i].style.transform = 'translate(' + (dx / d * 3).toFixed(2) + 'px,' + (dy / d * 3).toFixed(2) + 'px)';
    }
  }, { passive: true });

  document.addEventListener('keydown', function (e) {
    if (!root) return;
    if (e.altKey && (e.key === 'g' || e.key === 'G')) { e.preventDefault(); if (A.open) { A.open = false; paint(); } else openPanel(); }
    if (e.key === 'Escape' && A.open) { A.open = false; paint(); }
  });

  // Se aparta de los paneles laterales de Incidents / AI Rules para no tapar sus botones.
  function place() {
    var d = document.querySelector('.tsocInc.has-drawer .tsocInc__drawer');
    var right = d ? Math.round(d.getBoundingClientRect().width) + 22 : 22;
    root.style.right = right + 'px';
  }

  function tick() {
    try {
      var p = location.pathname;
      var ok = /^\/app\//.test(p) && !/^\/app\/login/.test(p) && document.querySelector('#globalHeaderBars, .euiHeader');
      if (!ok) { if (root) { root.remove(); root = null; } if (island) { island.remove(); island = null; LV.key = null; } return; }
      me(); mount(); mountIsland(); paintIsland();
      if (!root.isConnected) document.body.appendChild(root);
      place();
      if (Date.now() - A.polled > (A.state === 'idle' ? 20000 : 5000)) poll();
      // Respuesta en directo: una búsqueda mínima cada 2 s, solo con la pestaña a la vista.
      if (!document.hidden && Date.now() - LV.at > 2000) pollLive();
      // Saludo una vez por sesión y presentación al entrar en cada sección.
      var sec = section();
      if (!A.greeted && !sstore('greeted')) {
        // Primera vez en la sesión: el saludo sustituye a la presentación de la sección actual.
        A.greeted = true; sstore('greeted', '1');
        if (sec) { sstore('seen.' + sec.id, '1'); A.section = sec.id; }
        setTimeout(function () { bubble('¡Hola! Soy Guardian 🤖 Protejo tus equipos día y noche. ¿Quieres que me presente?', [['hello', 'Preséntate'], ['open_guardian', 'Mi centro de mando']], 16000); }, 1500);
      }
      if (sec && sec.id !== A.section) {
        A.section = sec.id;
        if (!sstore('seen.' + sec.id)) {
          sstore('seen.' + sec.id, '1');
          setTimeout(function () { if (section() === sec) bubble(sec.name + ': ' + sec.say, [['more', 'Cuéntame más']]); }, 1200);
        }
      } else if (!sec) A.section = null;
    } catch (err) { /* nunca romper la página */ }
  }
  if (window.speechSynthesis) try { speechSynthesis.onvoiceschanged = function () {}; speechSynthesis.getVoices(); } catch (e) {}
  window.TSOCBot = { tone: function () { return situation().tone; }, svg: bot, trace: traceHtml, traceRow: traceRow, ms: fmtMs, idle: idleHtml,
    refresh: function () { LV.recAt = 0; LV.at = 0; A.polled = 0; } };
  setInterval(tick, 700);
})();
/* ==== fin TripleSOC assistant ==== */
