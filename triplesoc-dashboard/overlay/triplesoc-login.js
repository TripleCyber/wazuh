/* ==== TripleSOC login ====
   Portal de entrada "Cúpula · noche" (elegido por Vladimir; referencia: tarjeta tipo ventana con escena a la
   izquierda y acceso breve). Tarjeta blanca centrada: a la izquierda, una ciudad de noche protegida por una
   cúpula (canvas, imagen FIJA: se dibuja una vez a la resolución real de la pantalla y con semilla fija, así se ve
   nítida y siempre igual); a la derecha, el logo oficial, "Hi Analyst", qué hace el sistema en tres palabras y un
   único botón "Sign in with TripleEnable" (Logto / OpenID).
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
  // Escudo del logo oficial (brand/mark.svg.tpl con los colores de brand/brand.env).
  var MARK = '<path d="M32 3 57 11.5V30c0 15.5-10.6 26.3-25 31C17.6 56.3 7 45.5 7 30V11.5Z" fill="#161616" stroke="#4A4A4A" stroke-width="2.5"/>' +
    '<g fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="4">' +
    '<g stroke="#E5484D"><circle cx="21" cy="33" r="3.6" stroke-width="3"/><path d="M23.6 30.4 35.5 18.5"/><path d="M28.5 18H36v7.5"/></g>' +
    '<g stroke="#1AA54A"><circle cx="27" cy="46" r="3.6" stroke-width="3"/><path d="M29.6 43.4 43.5 29.5"/><path d="M36.5 29H44v7.5"/></g></g>';
  // Logo oficial completo (brand/logo.svg.tpl): "Triple" en verde y "SOC" en rojo.
  var LOGO = '<svg class="tsocPortal__logo" viewBox="0 0 320 72" role="img" aria-label="TripleSOC"><g transform="translate(2 4)">' + MARK + '</g>' +
    '<text x="74" y="49" font-family="Roboto, \'Segoe UI\', Inter, Helvetica, Arial, sans-serif" font-size="38" font-weight="700" ' +
    'letter-spacing="-0.5" fill="#1AA54A">Triple<tspan fill="#BB2227">SOC</tspan></text></svg>';

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

  // ---------------------------------------------------------------- cúpula de noche (canvas, imagen fija)
  // Generador con semilla: la misma ciudad y las mismas estrellas en cada visita y al cambiar el tamaño.
  function seeded(seed) {
    return function () {
      seed |= 0; seed = seed + 0x6D2B79F5 | 0;
      var t = Math.imul(seed ^ seed >>> 15, 1 | seed);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  function dome(c) {
    var x = c.getContext && c.getContext('2d');
    if (!x) return;
    function paint() {
      var w = c.clientWidth, h = c.clientHeight;
      if (!w || !h) return;
      // Resolución real del dispositivo (sin tope bajo): es una sola pintura, así que puede ser nítida.
      var dpr = Math.min(window.devicePixelRatio || 1, 3);
      c.width = Math.round(w * dpr); c.height = Math.round(h * dpr); x.setTransform(dpr, 0, 0, dpr, 0, 0);
      var r = seeded(20261022), rnd = function (a, b) { return a + r() * (b - a); };

      // Cielo de noche en tonos neutros (azul noche a pizarra).
      var g = x.createLinearGradient(0, 0, 0, h);
      g.addColorStop(0, '#05070b'); g.addColorStop(.6, '#0b1018'); g.addColorStop(1, '#151c26');
      x.fillStyle = g; x.fillRect(0, 0, w, h);
      for (var i = 0; i < 140; i++) {
        var sy = r() * .5, big = r() < .08;
        x.fillStyle = 'rgba(235,240,245,' + (.35 + r() * .55) * (1 - sy) + ')';
        x.beginPath(); x.arc(r() * w, sy * h, big ? rnd(1, 1.5) : rnd(.35, .8), 0, 6.283); x.fill();
      }
      var hz = x.createLinearGradient(0, h * .55, 0, h);
      hz.addColorStop(0, 'rgba(120,140,160,0)'); hz.addColorStop(1, 'rgba(120,140,160,.18)');
      x.fillStyle = hz; x.fillRect(0, h * .55, w, h * .45);

      // Cúpula plateada con su malla y una franja de escaneo verde (fija).
      var cx = w * .45, cy = h * .98, R = Math.min(w * .62, h * .82), D = '205,215,225';
      var gl = x.createRadialGradient(cx, cy, R * .2, cx, cy, R * 1.05);
      gl.addColorStop(0, 'rgba(' + D + ',.06)'); gl.addColorStop(.92, 'rgba(' + D + ',.05)'); gl.addColorStop(1, 'rgba(' + D + ',0)');
      x.fillStyle = gl; x.beginPath(); x.arc(cx, cy, R * 1.05, Math.PI, 0); x.fill();
      x.strokeStyle = 'rgba(' + D + ',.11)'; x.lineWidth = 1;
      for (var k = 1; k < 6; k++) { x.beginPath(); x.ellipse(cx, cy, R, R * k / 6, 0, Math.PI, 0); x.stroke(); }
      for (var m = 1; m < 8; m++) {
        var a = Math.PI + m * Math.PI / 8;
        x.beginPath(); x.moveTo(cx, cy - R); x.quadraticCurveTo(cx + Math.cos(a) * R * 1.1, cy + Math.sin(a) * R * .6, cx + Math.cos(a) * R, cy); x.stroke();
      }
      var sp = .42, sy2 = cy - R * sp, hw = Math.sqrt(Math.max(0, R * R - (cy - sy2) * (cy - sy2)));
      var sg = x.createLinearGradient(0, sy2, 0, sy2 + R * .07);
      sg.addColorStop(0, 'rgba(26,165,74,.4)'); sg.addColorStop(1, 'rgba(26,165,74,0)');
      x.fillStyle = sg; x.fillRect(cx - hw, sy2, hw * 2, R * .07);
      x.strokeStyle = 'rgba(' + D + ',.75)'; x.lineWidth = 1.4; x.shadowColor = 'rgba(' + D + ',.7)'; x.shadowBlur = 12;
      x.beginPath(); x.arc(cx, cy, R, Math.PI, 0); x.stroke(); x.shadowBlur = 0;

      // Ciudad: edificios carbón, ventanas cálidas y balizas rojas en los más altos.
      var x0 = 0;
      while (x0 < 1) {
        var bw = rnd(.025, .06), bh = rnd(.12, .42) * (1 - Math.abs(x0 - .45) * .9), bx = x0 * w, bwp = bw * w, bhp = bh * h, by = h - bhp;
        x.fillStyle = '#07090c'; x.fillRect(bx, by, bwp, bhp);
        for (var j = 0; j < 26; j++) {
          var on = r() < .5, warm = r() < .75, u = r(), v = r(), al = .5 + r() * .35;
          if (!on) continue;
          x.fillStyle = (warm ? 'rgba(255,214,150,' : 'rgba(235,238,240,') + al + ')';
          x.fillRect(Math.round(bx + 2 + u * (bwp - 5)), Math.round(by + 4 + v * (bhp - 8)), 1.6, 1.6);
        }
        if (bh > .3 && r() < .6) {
          var px = bx + bwp / 2, py = by - 2, bg = x.createRadialGradient(px, py, 0, px, py, 9);
          bg.addColorStop(0, 'rgba(229,72,77,.45)'); bg.addColorStop(1, 'rgba(229,72,77,0)');
          x.fillStyle = bg; x.fillRect(px - 9, py - 9, 18, 18);
          x.fillStyle = 'rgba(229,72,77,.95)'; x.beginPath(); x.arc(px, py, 1.8, 0, 6.283); x.fill();
        }
        x0 += bw + rnd(0, .006);
      }
    }
    paint();
    // Solo se vuelve a pintar si cambia el tamaño (misma semilla: misma imagen).
    var t = 0;
    window.addEventListener('resize', function () { clearTimeout(t); t = setTimeout(paint, 120); });
  }

  function build() {
    var root = document.createElement('section');
    root.id = 'tsoc-login';
    root.className = 'tsocPortal';
    root.innerHTML =
      '<div class="tsocPortal__card">' +
      '<div class="tsocPortal__scene">' +
      '<canvas aria-hidden="true"></canvas>' +
      '<div class="tsocPortal__chip"><svg viewBox="0 0 64 64" aria-hidden="true">' + MARK + '</svg>' +
      '<div><b>Your whole organization</b><span>One shield over every device</span></div></div>' +
      '</div>' +
      '<div class="tsocPortal__auth">' + LOGO +
      '<h1 class="tsocPortal__hi">Hi Analyst</h1>' +
      '<p class="tsocPortal__sub">Welcome back to TripleSOC</p>' +
      '<p class="tsocPortal__does">Detect<i class="is-green"></i>Investigate<i class="is-red"></i>Respond</p>' +
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

  // Arranque temprano: en /app/login, bootstrap.js carga este mismo archivo desde /ui/ (window.__tsocBoot)
  // antes que la aplicación, así el portal sale enseguida en lugar de "Loading..." y del login nativo.
  var noOidc = 0;
  function tick() {
    try {
      var el = document.getElementById('tsoc-login');
      if (!isLogin() || localMode()) { document.body.classList.remove('tsoc-login'); if (el) el.remove(); return; }
      var wrapper = document.querySelector('.login-wrapper');
      if (!wrapper && !window.__tsocBoot) return;
      // Solo si Logto está configurado (existe el botón nativo de OpenID); si no, login nativo intacto.
      if (wrapper && !document.querySelector('a[aria-label="openid_login_button"]')) {
        if (++noOidc < 5) return;
        document.body.classList.remove('tsoc-login'); if (el) el.remove(); return;
      }
      if (!el) {
        el = build();
        document.body.appendChild(el);
        dome(el.querySelector('canvas'));
        document.title = 'Sign in · TripleSOC';
      }
      document.body.classList.add('tsoc-login');
      // El formulario nativo queda tapado y fuera del orden de tabulación (sin inert: deja la pestaña sin capturas).
      if (wrapper) tabbable(wrapper, false);
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
