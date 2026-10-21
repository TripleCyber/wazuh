/* ==== TripleSOC login ====
   Portal de entrada con el estilo del portal de TripleEnable (tenant.idp.tripleenable.com):
   "Welcome to TripleSOC", ventajas y un botón principal "Sign in with TripleEnable" (Logto / OpenID).
   El formulario nativo de usuario/contraseña NO se quita: queda plegado en "Use a local account"
   (respaldo si Logto no responde). No mueve nodos de React: añade los suyos y oculta los nativos por CSS
   (clase tsoc-login en <body>). Si una versión futura cambia el login, se ve el login nativo de siempre.
   apply-branding.sh lo AÑADE al final de core.entry.js. */
;(function () {
  'use strict';
  if (window.__tsocLogin) return;
  window.__tsocLogin = true;

  var FEATURES = [
    'Real-time threat detection with correlated incidents ready for triage',
    'Automated response with analyst approval, full audit trail and one-click undo',
    'AI-assisted detection rules and a security copilot, protected by guardrails'
  ];
  var MODULES = [
    ['Security Overview', 'Live posture of your agents, alerts and trust zones.'],
    ['Incidents', 'Correlated threats with context, ready for investigation.'],
    ['Guardian', 'Autonomous response that acts within the limits you set.']
  ];
  var CHECK = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" ' +
    'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>';

  // Sin aria-hidden por el mismo motivo que inert (la contraseña autocompletada deja la pestaña sin capturas).
  function tabbable(wrapper, on) {
    var els = wrapper.querySelectorAll('input, button, a');
    for (var i = 0; i < els.length; i++) if (els[i].tabIndex !== (on ? 0 : -1)) els[i].tabIndex = on ? 0 : -1;
  }

  function isLogin() { return /\/app\/login\/?$/.test(location.pathname); }

  // El enlace nativo de OpenID ya trae nextUrl cuando corresponde: se usa el suyo al hacer clic.
  function oidcHref() {
    var a = document.querySelector('a[aria-label="openid_login_button"]');
    return (a && a.getAttribute('href')) || ('/auth/openid/captureUrlFragment' + location.search);
  }

  function build(wrapper) {
    var root = document.createElement('section');
    root.id = 'tsoc-login';
    root.className = 'tsocLogin';
    root.innerHTML =
      '<div class="tsocLogin__mark"><span><img src="/ui/logos/wazuh_mark_on_dark.svg" alt=""></span></div>' +
      '<h1 class="tsocLogin__title">Welcome to TripleSOC</h1>' +
      '<p class="tsocLogin__lead">Detect, investigate and respond to threats across your organization from a single security operations center.</p>' +
      '<ul class="tsocLogin__card">' + FEATURES.map(function (f) { return '<li>' + CHECK + '<span>' + f + '</span></li>'; }).join('') + '</ul>' +
      '<a class="tsocLogin__primary" href="/auth/openid/captureUrlFragment">Sign in with TripleEnable</a>' +
      '<button type="button" class="tsocLogin__local" aria-expanded="false">Use a local account</button>';
    root.querySelector('.tsocLogin__primary').addEventListener('click', function (ev) {
      ev.preventDefault();
      ev.currentTarget.classList.add('is-busy');
      ev.currentTarget.textContent = 'Redirecting to TripleEnable…';
      window.location.href = oidcHref();
    });
    root.querySelector('.tsocLogin__local').addEventListener('click', function (ev) {
      var open = document.body.classList.toggle('tsoc-login--local');
      ev.currentTarget.setAttribute('aria-expanded', String(open));
      ev.currentTarget.textContent = open ? 'Hide local account' : 'Use a local account';
      tabbable(wrapper, open);
      if (open) { var u = wrapper.querySelector('input'); if (u) u.focus(); }
    });

    var foot = document.createElement('footer');
    foot.id = 'tsoc-login-foot';
    foot.className = 'tsocLogin__foot';
    foot.innerHTML = MODULES.map(function (m) { return '<div><b>' + m[0] + '</b><span>' + m[1] + '</span></div>'; }).join('') +
      '<p class="tsocLogin__legal">Secured by TripleEnable Identity · OpenID Connect · © ' + new Date().getFullYear() + ' TripleCyber</p>';
    return [root, foot];
  }

  function tick() {
    try {
      if (!isLogin()) { document.body.classList.remove('tsoc-login', 'tsoc-login--local'); return; }
      var wrapper = document.querySelector('.login-wrapper');
      if (!wrapper) return;
      // Solo si Logto está configurado (existe el botón nativo de OpenID); si no, login nativo intacto.
      if (!document.querySelector('a[aria-label="openid_login_button"]')) return;
      if (!document.getElementById('tsoc-login')) {
        var parts = build(wrapper);
        wrapper.parentNode.insertBefore(parts[0], wrapper);
        wrapper.parentNode.insertBefore(parts[1], wrapper.nextSibling);
        document.title = 'Sign in · TripleSOC';
      }
      // Si el inicio de sesión local falló, el formulario se queda abierto para ver el error.
      if (wrapper.querySelector('.euiCallOut--danger, .euiFormErrorText')) document.body.classList.add('tsoc-login--local');
      document.body.classList.add('tsoc-login');
      // Plegado: fuera del orden de tabulación (sin inert: igual que display:none, deja la pestaña sin capturas).
      tabbable(wrapper, document.body.classList.contains('tsoc-login--local'));
    } catch (err) { /* nunca romper la página de entrada */ }
  }
  setInterval(tick, 300);
  tick();
})();
/* ==== fin TripleSOC login ==== */
