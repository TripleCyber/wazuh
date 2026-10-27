/* ==== TripleSOC nav ====
   Entradas propias del menú lateral (diseño de referencia TripleSOC): selector, Overview, Attack Map,
   Trust Zones, Analytics, Alerts (con contador), APIs, Entities, sección ZONES y usuario al pie.
   apply-branding.sh lo AÑADE al final de core.entry.js: no modifica código existente.
   Solo usa el DOM del menú nativo; si una versión futura lo cambia, el menú nativo sigue
   funcionando igual y estas entradas simplemente no aparecen. Para quitarlo: reconstruir sin él. */
;(function () {
  'use strict';
  if (window.__tsocNav) return;
  window.__tsocNav = true;

  var TS = window.TSOC_SCHEMA; // capa traductora (triplesoc-schema.js): índice y campos de alertas
  if (!TS) return;
  var INDEX = TS.idx.alerts;
  // Reconoce en la URL la consulta DQL q (así se marca la entrada activa del menú).
  function qre(q) { return new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + "'"); }
  // Lista de alertas (Discover) de las últimas 24 h con una consulta DQL.
  function alerts(q) {
    return "/app/data-explorer/discover#?_a=(discover:(columns:!(" + TS.columns.join(',') + "),isDirty:!f,sort:!())," +
      "metadata:(indexPattern:'" + INDEX + "',view:discover))&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-24h,to:now))" +
      "&_q=(filters:!(),query:(language:kuery,query:'" + q + "'))";
  }
  var I = { // iconos (trazo, 24x24)
    grid: '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
    shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
    chart: '<path d="M3 3v18h18"/><path d="M7 15l4-4 3 3 5-6"/>',
    siren: '<path d="M7 18v-6a5 5 0 0 1 10 0v6"/><path d="M5 21h14v-3H5zM12 3v1M4.2 6.2l.7.7M19.8 6.2l-.7.7"/>',
    bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a2 2 0 0 0 3.4 0"/>',
    bot: '<rect x="4" y="8" width="16" height="12" rx="4"/><path d="M12 4v4M9 13h.01M15 13h.01M9 17h6"/><circle cx="12" cy="3" r="1"/>',
    spark: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/>',
    code: '<path d="m16 18 6-6-6-6M8 6l-6 6 6 6"/>',
    db: '<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v14c0 1.7 3.6 3 8 3s8-1.3 8-3V5M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>'
  };
  // Cada entrada dice para qué sirve la pantalla (línea "does") y va agrupada por lo que la persona quiere hacer.
  var MAIN = [
    { group: 'Proteger' },
    { label: 'Guardian', icon: 'bot', tone: 'green', does: 'Qué hace el agente ahora y qué detuvo', href: '/app/dashboards#/view/triplesoc-guardian', match: /^\/app\/dashboards.*view\/triplesoc-guardian/ },
    { label: 'Overview', icon: 'grid', tone: 'blue', does: 'Resumen: alertas, gravedad y equipos', href: '/app/dashboards#/view/triplesoc-overview', match: /^\/app\/dashboards.*view\/triplesoc-overview/ },
    { group: 'Investigar' },
    { label: 'Incidents', icon: 'siren', tone: 'red', does: 'Ataques agrupados y qué hacer con cada uno', href: '/app/dashboards#/view/triplesoc-incidents', match: /^\/app\/dashboards.*view\/triplesoc-incidents/, badge: 'incidents' },
    { label: 'Alerts', icon: 'bell', tone: 'amber', does: 'Alertas graves de las últimas 24 h', href: alerts(TS.kql.critical), match: qre(TS.kql.critical), badge: 'alerts' },
    { label: 'Analytics', icon: 'chart', tone: 'cyan', does: 'Buscar y revisar cada evento', href: alerts(''), match: /^\/app\/data-explorer\/discover(?!.*rule\.level)/ },
    { label: 'Attack Map', icon: 'globe', tone: 'violet', does: 'Técnicas de ataque vistas (MITRE)', href: '/app/dashboards#/view/triplesoc-attack', match: /^\/app\/dashboards.*view\/triplesoc-attack/ },
    { group: 'Configurar' },
    { label: 'AI Rules', icon: 'spark', tone: 'violet', does: 'Crear reglas de detección con IA', href: '/app/dashboards#/view/triplesoc-rules', match: /^\/app\/dashboards.*view\/triplesoc-rules/, badge: 'rules' },
    { label: 'Entities', icon: 'db', tone: 'blue', does: 'Equipos protegidos y su estado', href: '/app/dashboards#/view/triplesoc-entities', match: /^\/app\/dashboards.*view\/triplesoc-entities/ },
    { label: 'Trust Zones', icon: 'shield', tone: 'green', does: 'Grupos de equipos y su vigilancia', href: '/app/dashboards#/view/triplesoc-zones', match: /^\/app\/dashboards.*view\/triplesoc-zones/ },
    { label: 'APIs', icon: 'code', tone: 'slate', does: 'Conexión con el servidor y frescura de los datos', href: '/app/dashboards#/view/triplesoc-platform', match: /^\/app\/dashboards.*view\/triplesoc-platform/ }
  ];
  var ZONES = [
    { label: 'Anonymous', dot: 'red', href: alerts(TS.kql.critical), match: null },
    { label: 'Verified', dot: 'blue', href: alerts(TS.kql.high), match: qre(TS.kql.high) },
    { label: 'Secure', dot: 'green', href: alerts(TS.kql.low), match: qre(TS.kql.low) }
  ];

  function el(tag, cls, html) { var e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; }
  function svg(name) { return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + I[name] + '</svg>'; }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

  // Navegación dentro de la aplicación (sin recargar): el router del dashboard escucha popstate.
  function go(e, href) {
    if (e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return; // nueva pestaña: normal
    e.preventDefault();
    try {
      history.pushState(null, '', href);
      window.dispatchEvent(new PopStateEvent('popstate', { state: null }));
    } catch (err) { location.href = href; return; }
    if (document.querySelector('.euiOverlayMask')) { // menú flotante (no anclado): cerrarlo como hace el nativo
      var close = document.querySelector('.euiCollapsibleNav [data-test-subj="euiFlyoutCloseButton"]');
      if (close) close.click();
    }
    refresh();
  }
  function link(item, inner) {
    var a = el('a', 'tsocNav__item', inner);
    a.href = item.href;
    a.addEventListener('click', function (e) { go(e, item.href); });
    a._tsoc = item;
    return a;
  }

  function build() {
    var root = el('div', 'tsocNav');
    root.id = 'tsoc-nav';
    var sel = link({ href: MAIN[0].href }, '<span class="tsocNav__dot tsocNav__dot--green"></span><span class="tsocNav__selText">TripleSOC<br><b>Dashboard</b></span>' +
      '<svg class="tsocNav__chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m6 9 6 6 6-6"/></svg>');
    sel.className = 'tsocNav__selector';
    root.appendChild(sel);
    MAIN.forEach(function (it) {
      if (it.group) { root.appendChild(el('div', 'tsocNav__group', esc(it.group))); return; }
      var a = link(it, '<span class="tsocNav__ico tsocNav__ico--' + it.tone + '">' + svg(it.icon) + '</span>' +
        '<span class="tsocNav__label"><b>' + esc(it.label) + '</b><small>' + esc(it.does) + '</small></span>' +
        (it.badge ? '<span class="tsocNav__badge" data-badge="' + it.badge + '" hidden></span>' : ''));
      a.classList.add('tsocNav__item--rich');
      a.title = it.label + ' — ' + it.does;
      root.appendChild(a);
    });
    root.appendChild(el('div', 'tsocNav__section', 'Zones'));
    ZONES.forEach(function (z) {
      root.appendChild(link(z, '<span class="tsocNav__dot tsocNav__dot--' + z.dot + '"></span><span class="tsocNav__label">' + esc(z.label) + '</span>'));
    });
    root.appendChild(el('div', 'tsocNav__rule'));
    return root;
  }

  // Cerrar sesión: lo mismo que el "Log out" del plugin de seguridad (POST /auth/logout borra la cookie de
  // sesión; luego se limpia la sesión del navegador y se vuelve al login). Si la petición falla, igualmente al login.
  function logout(ev) {
    var b = ev.currentTarget; b.disabled = true;
    // Con Logto (OpenID) la respuesta trae redirectURL para cerrar también la sesión allí.
    fetch('/auth/logout', { method: 'POST', credentials: 'same-origin', headers: { 'osd-xsrf': 'true' } })
      .then(function (r) { return r.json(); })
      .catch(function () { return {}; })
      .then(function (j) {
        try { sessionStorage.clear(); } catch (e) {}
        window.location.href = (j && j.redirectURL) || ('/app/login?nextUrl=' + encodeURIComponent('/'));
      });
  }

  var account = null; // se pide una vez por carga de página (el menú se vuelve a montar al abrirlo)
  function buildUser() {
    var u = el('div', 'tsocNav__user');
    u.id = 'tsoc-nav-user';
    u.innerHTML = '<span class="tsocNav__avatar">·</span><span class="tsocNav__who"><b></b><small></small></span>' +
      '<button type="button" class="tsocNav__logout" title="Cerrar sesión" aria-label="Cerrar sesión">' +
      '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
      '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></svg></button>';
    u.querySelector('.tsocNav__logout').addEventListener('click', logout);
    account = account || fetch('/api/v1/configuration/account', { credentials: 'same-origin' }).then(function (r) { return r.ok ? r.json() : null; });
    account.then(function (j) {
      var d = j && j.data; if (!d || !d.user_name) { u.hidden = true; return; }
      var name = d.user_name.charAt(0).toUpperCase() + d.user_name.slice(1);
      var roles = d.roles || [];
      u.querySelector('.tsocNav__avatar').textContent = name.charAt(0);
      u.querySelector('b').textContent = name;
      u.querySelector('small').textContent = roles.indexOf('all_access') >= 0 ? 'Administrator' : (roles[0] || 'User');
    }).catch(function () { u.hidden = true; });
    return u;
  }

  // Contadores (misma vía de búsqueda que usa el dashboard, con los permisos del usuario):
  //   Alerts = alertas de nivel >= 12 en las últimas 24 h; Incidents = incidentes en estado "new".
  var BADGES = {
    alerts: { index: INDEX, query: { bool: { filter: [{ range: { timestamp: { gte: 'now-24h' } } }, TS.sevGte(TS.CRITICAL)] } } },
    incidents: { index: 'triplesoc-incidents', query: { term: { status: 'new' } } },
    // AI Rules = reglas redactadas por la IA pendientes de revisión.
    rules: { index: 'triplesoc-incidents-rules', query: { term: { status: 'proposed' } } }
  };
  var badgeValues = {}, badgeAt = 0;
  function updateBadge() {
    if (Date.now() - badgeAt < 60000) return paintBadge();
    badgeAt = Date.now();
    Object.keys(BADGES).forEach(function (k) {
      fetch('/internal/search/opensearch', {
        method: 'POST', credentials: 'same-origin',
        headers: { 'osd-xsrf': 'true', 'content-type': 'application/json' },
        body: JSON.stringify({ params: { index: BADGES[k].index, body: { size: 0, track_total_hits: true, query: BADGES[k].query } } })
      }).then(function (r) { return r.ok ? r.json() : null; }).then(function (j) {
        var t = j && j.rawResponse && j.rawResponse.hits && j.rawResponse.hits.total;
        badgeValues[k] = typeof t === 'number' ? t : (t && t.value != null ? t.value : null);
        paintBadge();
      }).catch(function () { badgeValues[k] = null; paintBadge(); });
    });
  }
  function paintBadge() {
    var bs = document.querySelectorAll('#tsoc-nav .tsocNav__badge');
    for (var i = 0; i < bs.length; i++) {
      var v = badgeValues[bs[i].getAttribute('data-badge')];
      bs[i].hidden = !v;
      bs[i].textContent = v > 99 ? '99+' : String(v || '');
    }
  }

  function refresh() {
    var here = location.pathname + decodeURIComponent(location.hash);
    var items = document.querySelectorAll('#tsoc-nav .tsocNav__item');
    for (var i = 0; i < items.length; i++) {
      var m = items[i]._tsoc && items[i]._tsoc.match;
      items[i].classList.toggle('tsocNav__item--active', !!(m && m.test(here)));
    }
  }

  // Para la isla del asistente: icono y propósito de la pantalla actual (misma lista que el menú).
  window.TSOCNav = {
    svg: function (name) { return I[name] ? svg(name) : ''; },
    here: function () {
      var here = location.pathname + decodeURIComponent(location.hash);
      for (var i = 0; i < MAIN.length; i++) if (MAIN[i].match && MAIN[i].match.test(here)) return MAIN[i];
      return null;
    }
  };

  var lastUrl = '';
  function tick() {
    try {
      var nav = document.querySelector('.euiCollapsibleNav');
      var scroll = nav && nav.querySelector('.eui-yScroll');
      if (!scroll) return;
      if (!document.getElementById('tsoc-nav')) { scroll.insertBefore(build(), scroll.firstChild); lastUrl = ''; badgeAt = 0; }
      if (!document.getElementById('tsoc-nav-user')) nav.appendChild(buildUser());
      if (location.href !== lastUrl) { lastUrl = location.href; refresh(); }
      updateBadge();
    } catch (err) { /* nunca romper la página por el menú */ }
  }
  setInterval(tick, 500);
})();
/* ==== fin TripleSOC nav ==== */
