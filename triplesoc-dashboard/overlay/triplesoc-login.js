/* ==== TripleSOC login ====
   Portal de entrada "El escudo bloquea": texto grande a la izquierda, un único botón "Sign in with TripleEnable"
   (Logto / OpenID) y, a la derecha, una red con forma de escudo contra la que chocan amenazas (canvas).
   El formulario nativo de usuario/contraseña NO se quita del código: queda tapado y solo se usa entrando por
   /app/login?local (respaldo del admin local si Logto no responde). No mueve nodos de React: añade una capa
   fija propia (clase tsoc-login en <body>). Si una versión futura cambia el login, se ve el login nativo.
   Incluye la puerta de acceso: una cuenta sin rol de TripleSOC ve "Access not granted" en lugar del panel.
   apply-branding.sh lo AÑADE al final de core.entry.js. */
;(function () {
  'use strict';
  if (window.__tsocLogin) return;
  window.__tsocLogin = true;

  var ARROW = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" ' +
    'stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg>';

  // Sin aria-hidden por el mismo motivo que inert (la contraseña autocompletada deja la pestaña sin capturas).
  function tabbable(wrapper, on) {
    var els = wrapper.querySelectorAll('input, button, a');
    for (var i = 0; i < els.length; i++) if (els[i].tabIndex !== (on ? 0 : -1)) els[i].tabIndex = on ? 0 : -1;
  }

  function isLogin() { return /\/app\/login\/?$/.test(location.pathname); }
  // Respaldo: /app/login?local muestra el login nativo (usuario y contraseña) sin el portal.
  function localMode() { return /[?&]local(=|&|$)/.test(location.search); }

  // El enlace nativo de OpenID ya trae nextUrl cuando corresponde: se usa el suyo al hacer clic.
  function oidcHref() {
    var a = document.querySelector('a[aria-label="openid_login_button"]');
    return (a && a.getAttribute('href')) || ('/auth/openid/captureUrlFragment' + location.search);
  }

  // ---------------------------------------------------------------- escudo (canvas)
  var G = '34,197,94', M = '134,239,172', R = '240,82,82';
  function rnd(a, b) { return a + Math.random() * (b - a); }
  // Silueta del escudo en coordenadas 0..1 (u horizontal, v vertical).
  function half(v) { return v < .45 ? .5 - (v < .06 ? (.06 - v) * 1.2 : 0) : .5 * Math.sqrt(Math.max(0, 1 - Math.pow((v - .45) / .55, 2))); }
  function inShield(u, v) { return v >= 0 && v <= 1 && Math.abs(u - .5) < half(v); }

  function shield(root, c, counter) {
    var x = c.getContext && c.getContext('2d');
    if (!x) return;
    var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
    var nodes = [], E = [], threats = [], sparks = [], hits = [], last = 0, prev = 0, count = 0, w = 0, h = 0;
    var mouse = { x: -1e4, y: -1e4 };
    for (var i = 0; i < 44; i++) { var q = i / 44, v = q < .5 ? q * 2 : (1 - q) * 2, s = q < .5 ? -1 : 1; nodes.push({ u: .5 + s * half(v) * .985, v: v, rim: true }); }
    while (nodes.length < 165) { var u = Math.random(), vv = Math.random(); if (inShield(u, vv) && Math.abs(u - .5) < half(vv) * .92) nodes.push({ u: u, v: vv }); }
    nodes.forEach(function (n) { n.ph = rnd(0, 6.283); });
    for (var a = 0; a < nodes.length; a++) for (var b = a + 1; b < nodes.length; b++) {
      var d = Math.hypot(nodes[a].u - nodes[b].u, (nodes[a].v - nodes[b].v) * 1.2); if (d < .125) E.push([a, b, d]);
    }
    function size() {
      var dpr = Math.min(window.devicePixelRatio || 1, 2); w = c.clientWidth; h = c.clientHeight;
      c.width = w * dpr; c.height = h * dpr; x.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    function glow(cx, cy, r, col, al) {
      var g = x.createRadialGradient(cx, cy, 0, cx, cy, r); g.addColorStop(0, 'rgba(' + col + ',' + al + ')'); g.addColorStop(1, 'rgba(' + col + ',0)');
      x.fillStyle = g; x.fillRect(cx - r, cy - r, r * 2, r * 2);
    }
    function draw(t) {
      x.clearRect(0, 0, w, h);
      // Movimiento por tiempo (no por fotograma); con tope al volver de otra pestaña.
      var dt = prev ? Math.min(4, (t - prev) / 16.7) : 1; prev = t;
      // En pantallas estrechas el escudo va centrado arriba, detrás del texto.
      var narrow = w < 760, S = narrow ? Math.min(h * .46, w * .8) : Math.min(h * .7, w * .5), sw = S * .82;
      var ox = (narrow ? w * .5 : w * .68) - sw / 2, oy = narrow ? h * .1 : (h - S) / 2;
      glow(ox + sw / 2, oy + S / 2, S * .7, G, .1);
      if (t - last > 900) { last = t; threats.push({ x: w + 20, y: rnd(oy + S * .1, oy + S * .85), vx: -rnd(2.6, 4.2), vy: rnd(-.3, .3), trail: [] }); }
      var P = nodes.map(function (n) {
        var px = ox + n.u * sw, py = oy + n.v * S, light = 0;
        hits.forEach(function (hh) { var dd = Math.hypot(px - hh.x, py - hh.y), age = (t - hh.t) / 1200; if (age < 1 && dd < S * .25) light = Math.max(light, (1 - age) * (1 - dd / (S * .25))); });
        return [px + Math.sin(t * .0008 + n.ph) * 2, py + Math.cos(t * .0007 + n.ph) * 2, light];
      });
      E.forEach(function (e) {
        var p = P[e[0]], q = P[e[1]], l = Math.max(p[2], q[2]);
        x.strokeStyle = 'rgba(' + (l > .05 ? M : G) + ',' + (.3 + l * .6) * (1 - e[2] / .125) + ')'; x.lineWidth = 1 + l;
        x.beginPath(); x.moveTo(p[0], p[1]); x.lineTo(q[0], q[1]); x.stroke();
      });
      P.forEach(function (p, k) {
        x.fillStyle = p[2] > .05 ? 'rgba(' + M + ',' + (.5 + p[2] * .5) + ')' : (nodes[k].rim ? 'rgba(' + M + ',.75)' : 'rgba(232,239,234,.6)');
        x.beginPath(); x.arc(p[0], p[1], 1.5 + p[2] * 1.5, 0, 6.283); x.fill();
      });
      threats = threats.filter(function (k) {
        k.trail.push([k.x, k.y]); if (k.trail.length > 22) k.trail.shift(); k.x += k.vx * dt; k.y += k.vy * dt;
        if (inShield((k.x - ox) / sw, (k.y - oy) / S)) {
          count++; if (counter) counter.textContent = count.toLocaleString('en-US'); hits.push({ x: k.x, y: k.y, t: t });
          for (var j = 0; j < 16; j++) { var an = rnd(-1.4, 1.4); sparks.push({ x: k.x, y: k.y, vx: Math.cos(an) * rnd(.6, 2.2), vy: Math.sin(an) * rnd(.6, 2.2), t: t, c: Math.random() < .5 ? R : M }); }
          return false;
        }
        x.strokeStyle = 'rgba(' + R + ',.5)'; x.lineWidth = 1.5; x.beginPath();
        k.trail.forEach(function (p, j) { j ? x.lineTo(p[0], p[1]) : x.moveTo(p[0], p[1]); }); x.stroke();
        glow(k.x, k.y, 10, R, .9);
        return k.x > -20;
      });
      hits = hits.filter(function (hh) { return t - hh.t < 1200; });
      sparks = sparks.filter(function (sp) {
        var age = (t - sp.t) / 700; if (age > 1) return false;
        sp.x += sp.vx * dt; sp.y += sp.vy * dt; sp.vx *= Math.pow(.96, dt); sp.vy *= Math.pow(.96, dt); x.fillStyle = 'rgba(' + sp.c + ',' + (1 - age) + ')'; x.fillRect(sp.x, sp.y, 2, 2);
        return true;
      });
      if (inShield((mouse.x - ox) / sw, (mouse.y - oy) / S)) glow(mouse.x, mouse.y, S * .18, M, .18);
    }
    size();
    window.addEventListener('resize', function () { size(); if (reduce) draw(0); });
    root.addEventListener('pointermove', function (e) { mouse.x = e.clientX; mouse.y = e.clientY; });
    root.addEventListener('pointerleave', function () { mouse.x = mouse.y = -1e4; });
    if (reduce) { draw(0); return; }
    // requestAnimationFrame se pausa solo con la pestaña en segundo plano; se detiene al salir del login.
    (function loop(t) { if (!root.isConnected) return; draw(t || 0); requestAnimationFrame(loop); })();
  }

  function build() {
    var root = document.createElement('section');
    root.id = 'tsoc-login';
    root.className = 'tsocPortal';
    root.innerHTML =
      '<canvas class="tsocPortal__net" aria-hidden="true"></canvas>' +
      '<div class="tsocPortal__brand"><img src="/ui/logos/wazuh_mark_on_dark.svg" alt=""><span>TripleSOC</span></div>' +
      '<div class="tsocPortal__copy">' +
      '<span class="tsocPortal__eyebrow">Live protection</span>' +
      '<h1 class="tsocPortal__title">Welcome to<b>TripleSOC</b></h1>' +
      '<a class="tsocPortal__cta" href="/auth/openid/captureUrlFragment"><span>Sign in with TripleEnable</span>' + ARROW + '</a>' +
      '</div>' +
      '<p class="tsocPortal__legal">Secured by TripleEnable Identity · OpenID Connect · © ' + new Date().getFullYear() + ' TripleCyber</p>' +
      '<div class="tsocPortal__hud" aria-hidden="true"><b>0</b>threats stopped</div>';
    root.querySelector('.tsocPortal__cta').addEventListener('click', function (ev) {
      ev.preventDefault();
      ev.currentTarget.classList.add('is-busy');
      ev.currentTarget.querySelector('span').textContent = 'Redirecting to TripleEnable…';
      window.location.href = oidcHref();
    });
    return root;
  }

  function tick() {
    try {
      var el = document.getElementById('tsoc-login');
      if (!isLogin() || localMode()) { document.body.classList.remove('tsoc-login'); if (el) el.remove(); return; }
      var wrapper = document.querySelector('.login-wrapper');
      if (!wrapper) return;
      // Solo si Logto está configurado (existe el botón nativo de OpenID); si no, login nativo intacto.
      if (!document.querySelector('a[aria-label="openid_login_button"]')) return;
      if (!el) {
        el = build();
        document.body.appendChild(el);
        shield(el, el.querySelector('canvas'), el.querySelector('.tsocPortal__hud b'));
        document.title = 'Sign in · TripleSOC';
      }
      document.body.classList.add('tsoc-login');
      // El formulario nativo queda tapado y fuera del orden de tabulación (sin inert: deja la pestaña sin capturas).
      tabbable(wrapper, false);
    } catch (err) { /* nunca romper la página de entrada */ }
  }
  setInterval(tick, 300);
  tick();

  // ---------------------------------------------------------------- puerta de acceso
  // Una cuenta de TripleEnable sin rol de TripleSOC (tsoc-admin / tsoc-analista / tsoc-lectura) inicia sesión
  // pero no recibe permisos: el indexer solo le da own_index y la API de Wazuh ninguno (ops/oidc/wazuh-rbac.sh).
  // Aquí además no ve el panel: pantalla "Access not granted" y cerrar sesión. Si la consulta falla, no bloquea
  // (la protección de los datos está en el servidor, esto es la experiencia de usuario).
  function signOut(btn) {
    btn.disabled = true; btn.textContent = 'Signing out…';
    fetch('/auth/logout', { method: 'POST', credentials: 'same-origin', headers: { 'osd-xsrf': 'true' } })
      .then(function (r) { return r.json(); })
      .catch(function () { return {}; })
      .then(function (j) {
        try { sessionStorage.clear(); } catch (e) {}
        window.location.href = (j && j.redirectURL) || '/app/login';
      });
  }

  function deny(name) {
    if (document.getElementById('tsoc-denied')) return;
    var esc = function (s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); };
    var d = document.createElement('section');
    d.id = 'tsoc-denied';
    d.className = 'tsocLogin tsocDenied';
    d.setAttribute('role', 'alertdialog');
    d.setAttribute('aria-labelledby', 'tsoc-denied-title');
    d.innerHTML =
      '<div class="tsocLogin__mark tsocDenied__mark"><span><img src="/ui/logos/wazuh_mark_on_dark.svg" alt=""></span></div>' +
      '<h1 class="tsocLogin__title" id="tsoc-denied-title">Access not granted</h1>' +
      '<p class="tsocLogin__lead">You are signed in with TripleEnable, but this account has not been assigned a TripleSOC role yet.</p>' +
      '<div class="tsocLogin__card tsocDenied__card">' +
      '<b>How to get access</b><span>Ask your TripleEnable administrator to grant you the <i>Admin</i>, <i>Analyst</i> or <i>Read-only</i> role, then sign in again.</span>' +
      (name ? '<small>Account ID: ' + esc(name) + '</small>' : '') + '</div>' +
      '<button type="button" class="tsocLogin__primary">Sign out</button>' +
      '<p class="tsocLogin__legal">Secured by TripleEnable Identity · OpenID Connect</p>';
    var btn = d.querySelector('.tsocLogin__primary');
    btn.addEventListener('click', function () { signOut(btn); });
    document.body.appendChild(d);
    document.body.classList.add('tsoc-denied');
    btn.focus();
  }

  // Para enseñar la pantalla sin una cuenta sin rol (consola: TSOCLogin.previewDenied()). No concede nada.
  window.TSOCLogin = { previewDenied: function () { deny('preview'); } };

  if (!isLogin() && !/^\/auth\//.test(location.pathname)) {
    fetch('/api/v1/configuration/account', { credentials: 'same-origin' })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) {
        var a = j && (j.data || j);
        if (!a || !Array.isArray(a.roles)) return;
        // own_index lo recibe cualquier usuario autenticado (users "*"): no cuenta como acceso.
        var real = a.roles.filter(function (r) { return r !== 'own_index'; });
        if (!real.length) deny(a.user_name);
      })
      .catch(function () { /* sin bloqueo si la consulta falla */ });
  }
})();
/* ==== fin TripleSOC login ==== */
