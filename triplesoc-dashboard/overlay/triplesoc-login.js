/* ==== TripleSOC login ====
   Portal de entrada "Aurora" (referencia de Vladimir: tarjeta tipo ventana, escena a la izquierda y acceso breve):
   una tarjeta centrada con una aurora verde sobre montañas (canvas) a la izquierda y, a la derecha, logo,
   "Hi Analyst", qué hace el sistema en tres palabras y un único botón "Sign in with TripleEnable" (Logto / OpenID).
   El formulario nativo de usuario/contraseña NO se quita del código: queda tapado y solo se usa entrando por
   /app/login#local (respaldo del admin local si Logto no responde). No mueve nodos de React: añade una capa
   fija propia (clase tsoc-login en <body>). Si una versión futura cambia el login, se ve el login nativo.
   Incluye la puerta de acceso: una cuenta sin rol de TripleSOC ve "Access not granted" en lugar del panel.
   apply-branding.sh lo AÑADE al final de core.entry.js. */
;(function () {
  'use strict';
  if (window.__tsocLogin) return;
  window.__tsocLogin = true;

  var ARROW = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" ' +
    'stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg>';
  var SHIELD = '<svg viewBox="0 0 24 24" fill="none" stroke="#86EFAC" stroke-width="2" stroke-linejoin="round" ' +
    'aria-hidden="true"><path d="M12 2 4 5v6c0 5 3.4 9.4 8 11 4.6-1.6 8-6 8-11V5z"/></svg>';

  // Sin aria-hidden por el mismo motivo que inert (la contraseña autocompletada deja la pestaña sin capturas).
  function tabbable(wrapper, on) {
    var els = wrapper.querySelectorAll('input, button, a');
    for (var i = 0; i < els.length; i++) if (els[i].tabIndex !== (on ? 0 : -1)) els[i].tabIndex = on ? 0 : -1;
  }

  function isLogin() { return /\/app\/login\/?$/.test(location.pathname); }
  // Respaldo: /app/login#local muestra el login nativo (usuario y contraseña) sin el portal.
  // Con # y no con ?: el servidor rechaza parámetros desconocidos en /app/login (400) y el # no le llega.
  function localMode() { return location.hash === '#local'; }

  // El enlace nativo de OpenID ya trae nextUrl cuando corresponde: se usa el suyo al hacer clic.
  function oidcHref() {
    var a = document.querySelector('a[aria-label="openid_login_button"]');
    return (a && a.getAttribute('href')) || ('/auth/openid/captureUrlFragment' + location.search);
  }

  // ---------------------------------------------------------------- aurora (canvas)
  function rnd(a, b) { return a + Math.random() * (b - a); }
  // Cresta de montaña por desplazamiento del punto medio (valores 0..1 de alto).
  function ridge(n, base, amp, rough) {
    var p = []; for (var i = 0; i <= n; i++) p.push(0);
    p[0] = rnd(-1, 1); p[n] = rnd(-1, 1);
    (function sub(a, b, s) {
      if (b - a < 2) return; var m = (a + b) >> 1;
      p[m] = (p[a] + p[b]) / 2 + rnd(-s, s); sub(a, m, s * rough); sub(m, b, s * rough);
    })(0, n, 1);
    return p.map(function (v) { return base + v * amp; });
  }

  function aurora(root, c) {
    var x = c.getContext && c.getContext('2d');
    if (!x) return;
    var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
    var w = 0, h = 0, stars = [], meteors = [], nextMeteor = 2000;
    for (var i = 0; i < 240; i++) stars.push({ x: Math.random(), y: Math.random() * .72, r: Math.random() < .08 ? rnd(1, 1.6) : rnd(.3, .9), ph: rnd(0, 6.28), tw: rnd(.0006, .002) });
    var ridges = [[ridge(64, .70, .07, .55), '#0a2a20'], [ridge(64, .80, .06, .55), '#061a14'], [ridge(64, .90, .04, .6), '#030d0a']];
    // Cintas de la aurora: [altura base, color, velocidad, intensidad]
    var bands = [[.22, '34,197,94', .0004, .9], [.30, '45,212,191', .0003, .6], [.16, '134,239,172', .0005, .5]];

    function size() {
      var dpr = Math.min(window.devicePixelRatio || 1, 2); w = c.clientWidth; h = c.clientHeight;
      c.width = w * dpr; c.height = h * dpr; x.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    function draw(t) {
      var g = x.createLinearGradient(0, 0, 0, h);
      g.addColorStop(0, '#020a10'); g.addColorStop(.55, '#05201a'); g.addColorStop(.8, '#0b3a2a'); g.addColorStop(1, '#04120d');
      x.fillStyle = g; x.fillRect(0, 0, w, h);
      stars.forEach(function (s) {
        var a = .35 + .65 * Math.abs(Math.sin(t * s.tw + s.ph));
        x.fillStyle = 'rgba(230,245,236,' + a * (1 - s.y * .8) + ')'; x.beginPath(); x.arc(s.x * w, s.y * h, s.r, 0, 6.283); x.fill();
      });
      if (t > nextMeteor) { nextMeteor = t + rnd(2600, 5200); meteors.push({ x: rnd(.3, 1.1) * w, y: rnd(0, .25) * h, t0: t, len: rnd(60, 120), sp: rnd(.35, .55) }); }
      meteors = meteors.filter(function (m) {
        var p = (t - m.t0) / 1100; if (p > 1) return false;
        var hx = m.x - p * m.sp * w * .6, hy = m.y + p * m.sp * w * .3;
        var mg = x.createLinearGradient(hx, hy, hx + m.len, hy - m.len * .5);
        mg.addColorStop(0, 'rgba(240,255,246,' + (1 - p) + ')'); mg.addColorStop(1, 'rgba(240,255,246,0)');
        x.strokeStyle = mg; x.lineWidth = 1.4; x.beginPath(); x.moveTo(hx, hy); x.lineTo(hx + m.len, hy - m.len * .5); x.stroke();
        return true;
      });
      x.globalCompositeOperation = 'lighter';
      bands.forEach(function (b, bi) {
        for (var i = 0; i <= w; i += 3) {
          var u = i / w, y = h * (b[0] + .08 * Math.sin(u * 4 + t * b[2] + bi) + .04 * Math.sin(u * 11 - t * b[2] * 1.7));
          var hg = h * (.22 + .1 * Math.sin(u * 6 + t * .0007 + bi));
          var a = b[3] * (.35 + .65 * Math.pow(Math.sin(u * 3.14), 1.4)) * (.6 + .4 * Math.sin(u * 20 + t * .002 + bi));
          var gg = x.createLinearGradient(0, y, 0, y + hg);
          gg.addColorStop(0, 'rgba(' + b[1] + ',0)'); gg.addColorStop(.75, 'rgba(' + b[1] + ',' + (.55 * a) + ')'); gg.addColorStop(1, 'rgba(' + b[1] + ',0)');
          x.fillStyle = gg; x.fillRect(i, y, 3, hg);
        }
      });
      x.globalCompositeOperation = 'source-over';
      ridges.forEach(function (L) {
        x.fillStyle = L[1]; x.beginPath(); x.moveTo(0, h);
        L[0].forEach(function (v, i) { x.lineTo(i / (L[0].length - 1) * w, v * h); });
        x.lineTo(w, h); x.fill();
      });
    }
    size();
    window.addEventListener('resize', function () { size(); if (reduce) draw(3000); });
    if (reduce) { draw(3000); return; }
    // requestAnimationFrame se pausa solo con la pestaña en segundo plano; se detiene al salir del login.
    (function loop(t) { if (!root.isConnected) return; draw((t || 0) + 3000); requestAnimationFrame(loop); })();
  }

  function build() {
    var root = document.createElement('section');
    root.id = 'tsoc-login';
    root.className = 'tsocPortal';
    root.innerHTML =
      '<div class="tsocPortal__card">' +
      '<div class="tsocPortal__scene">' +
      '<canvas aria-hidden="true"></canvas>' +
      '<div class="tsocPortal__top"><span>TripleSOC</span><small>Live</small></div>' +
      '<div class="tsocPortal__chip"><span class="tsocPortal__ic">' + SHIELD + '</span>' +
      '<div><b>Always on watch</b><span>24/7 security operations</span></div></div>' +
      '</div>' +
      '<div class="tsocPortal__auth">' +
      '<div class="tsocPortal__logo"><img src="/ui/logos/wazuh_mark_on_dark.svg" alt=""><div>Triple<span>SOC</span><small>Security operations</small></div></div>' +
      '<h1 class="tsocPortal__hi">Hi Analyst</h1>' +
      '<p class="tsocPortal__sub">Welcome back to TripleSOC</p>' +
      '<p class="tsocPortal__does">Detect · Investigate · Respond</p>' +
      '<a class="tsocPortal__cta" href="/auth/openid/captureUrlFragment"><span>Sign in with TripleEnable</span>' + ARROW + '</a>' +
      '<p class="tsocPortal__legal">Secured by TripleEnable Identity · © ' + new Date().getFullYear() + ' TripleCyber</p>' +
      '</div>' +
      '</div>';
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
        aurora(el, el.querySelector('canvas'));
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
