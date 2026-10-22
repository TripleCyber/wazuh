/* ==== TripleSOC login boot ====
   Va al PRINCIPIO de bootstrap.js (plantilla legacy/ui/ui_render/bootstrap/template.js.hbs; sin llaves dobles,
   que son de Handlebars). Solo en /app/login (no en /app/login#local): tapa la pantalla "Loading..." oscura con
   el fondo del portal, carga la hoja TripleSOC y el portal (/ui/triplesoc-login.js, el mismo código que va en
   core.entry.js) sin esperar a la aplicación. Así al recargar no se ve el login nativo. Si algo falla, o el
   portal no aparece en 8 s, se quita el tapado y todo sigue como siempre. */
(function () {
  try {
    if (!/\/app\/login\/?$/.test(location.pathname) || location.hash === '#local') return;
    window.__tsocBoot = true;
    // Capa fija (no fondo del body: la hoja del tema lo pinta oscuro con !important). Queda debajo del portal;
    // triplesoc-login.js la quita si el portal no se usa (#local o sin OpenID).
    var cover = document.createElement('style');
    cover.id = 'tsoc-boot-cover';
    cover.textContent = 'html::before{content:"";position:fixed;inset:0;z-index:2147481000;' +
      'background:radial-gradient(circle at 25% 10%,#F4F5F5 0,#E6E8E7 50%,#D8DBDA 100%)}#osd_loading_message{display:none!important}';
    document.head.appendChild(cover);
    var reveal = function () { if (!document.getElementById('tsoc-login') && cover.parentNode) cover.remove(); };
    var css = document.createElement('link');
    css.rel = 'stylesheet';
    css.href = '/ui/wz_v7_theme_overwrite.css';
    css.onload = function () {
      var js = document.createElement('script');
      js.src = '/ui/triplesoc-login.js';
      js.onerror = reveal;
      document.head.appendChild(js);
    };
    css.onerror = reveal;
    document.head.appendChild(css);
    setTimeout(reveal, 8000);
  } catch (e) { /* nunca impedir que arranque la aplicación */ }
})();
/* ==== fin TripleSOC login boot ==== */

