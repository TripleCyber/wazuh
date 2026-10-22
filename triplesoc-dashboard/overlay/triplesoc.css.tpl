
/* ==== TripleSOC visual layer — generado por triplesoc-dashboard (no editar en el servidor) ==== */
/* Tema oscuro TripleSOC sobre el modo oscuro nativo (theme:darkMode = true por defecto). */
/* Estilo triplecyber.com/products/triplesoc: carbón neutro, verde TripleCyber como acción,
   rojo TripleCyber para lo crítico, tipografía Roboto. */
:root {
  --tsoc-dark: ${TSOC_DARK};
  --tsoc-deep: #111111;
  --tsoc-green: ${TSOC_GREEN};
  --tsoc-red: ${TSOC_RED_ON_DARK};
  --tsoc-gray: ${TSOC_GRAY};
  --tsoc-primary: ${TSOC_PRIMARY};
  --tsoc-primary-hover: ${TSOC_PRIMARY_HOVER};
  --tsoc-accent: ${TSOC_ACCENT};
  --tsoc-accent-rgb: ${TSOC_ACCENT_RGB};
  --tsoc-canvas: #171717;
  --tsoc-surface: #1F1F1F;
  --tsoc-surface-2: #262626;
  --tsoc-input: #141414;
  --tsoc-border: #2E2E2E;
  --tsoc-text: #E5E5E5;
  --tsoc-muted: #A3A3A3;
  --tsoc-radius: 12px;
  --tsoc-shadow: 0 1px 2px rgba(0, 0, 0, .35), 0 8px 24px rgba(0, 0, 0, .25);
  --tsoc-font: Roboto, "Segoe UI", "Inter UI", Inter, -apple-system, BlinkMacSystemFont, Helvetica, Arial, sans-serif;
}

/* ---------- Tipografía ---------- */
body, .euiText, .euiTitle, .euiButton, .euiButtonEmpty, .euiFieldText, .euiSelect, .euiTable,
.euiDataGrid, .euiTab, .euiBadge, .euiLink, .euiFormLabel, .euiListGroupItem__label, .euiStat__title {
  font-family: var(--tsoc-font) !important;
}

/* ---------- Base ---------- */
html, body, #opensearch-dashboards-body, .app-wrapper, .app-wrapper-panel, .euiPage, .euiPageBody,
.euiPageContent, .euiPageContentBody, .application, .osdAppWrapper {
  background-color: var(--tsoc-canvas) !important;
}
body { color: var(--tsoc-text); -webkit-font-smoothing: antialiased; }
.euiTitle, .euiText, .euiStat__title { color: var(--tsoc-text); }
.euiTitle { letter-spacing: -.01em; }
.euiText--subdued, .euiTextColor--subdued, .euiStat__description { color: var(--tsoc-muted) !important; }
::selection { background: rgba(var(--tsoc-accent-rgb), .30); }
::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-thumb { background: #3A3A3A; border-radius: 8px; border: 2px solid var(--tsoc-canvas); }
::-webkit-scrollbar-track { background: transparent; }

/* ---------- Encabezado ---------- */
.euiHeader {
  background: var(--tsoc-deep) !important;
  border-bottom: 1px solid var(--tsoc-border) !important;
  box-shadow: 0 2px 14px rgba(0, 0, 0, .45) !important;
}
.euiHeader .euiHeaderSectionItemButton, .euiHeader .euiHeaderSectionItem__button,
.euiHeader .euiHeaderLink, .euiHeader .euiButtonEmpty, .euiHeader .euiButtonIcon,
.euiHeader .euiHeaderSectionItem { color: var(--tsoc-text) !important; }
.euiHeader .euiHeaderSectionItem::after { background: rgba(255, 255, 255, .08) !important; }
.euiHeader .euiHeaderSectionItemButton:hover, .euiHeader .euiButtonEmpty:hover { background: rgba(255, 255, 255, .07) !important; }
.euiHeader .euiHeaderBreadcrumbs .euiBreadcrumbWrapper::before { background-color: rgba(var(--tsoc-accent-rgb), .14) !important; }
.euiHeader .euiHeaderBreadcrumbs .euiBreadcrumb, .euiHeader .euiHeaderBreadcrumbs .osdBreadcrumbs,
.euiHeader .euiHeaderBreadcrumbs .euiBreadcrumb a { color: var(--tsoc-muted) !important; }
.euiHeader .euiHeaderBreadcrumbs .euiBreadcrumb--last { color: #fff !important; font-weight: 600; }
.euiHeader .euiHeaderBreadcrumbs .euiBreadcrumb::after { background: rgba(163, 163, 163, .4) !important; }
.euiHeader .euiSuperSelectControl, .euiHeader .euiFieldText, .euiHeader .euiSelect, .euiHeader .euiFormControlLayout {
  background-color: rgba(255, 255, 255, .07) !important; color: #fff !important;
  border-color: rgba(255, 255, 255, .12) !important; box-shadow: none !important;
}
.euiHeader .euiFormLabel, .euiHeader .euiText { color: var(--tsoc-muted) !important; }

/* ---------- Navegación lateral ---------- */
.euiCollapsibleNav, .euiFlyout.euiCollapsibleNav { background: var(--tsoc-deep) !important; border-right: 1px solid var(--tsoc-border) !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup { background: transparent !important; border-color: var(--tsoc-border) !important; }
.euiCollapsibleNav .euiListGroupItem__label, .euiCollapsibleNav .euiListGroupItem__button,
.euiCollapsibleNav .euiAccordion__button, .euiCollapsibleNav .euiAccordion__buttonContent,
.euiCollapsibleNav .euiCollapsibleNavGroup__title, .euiCollapsibleNav .euiTitle,
.euiCollapsibleNav .euiLink, .euiCollapsibleNav .euiButtonEmpty, .euiCollapsibleNav .euiText { color: #D4D4D4 !important; }
.euiCollapsibleNav .euiIcon { filter: grayscale(1) brightness(0) invert(.82); }
.euiCollapsibleNav .euiListGroupItem:hover, .euiCollapsibleNav .euiAccordion__button:hover,
.euiCollapsibleNav .euiListGroupItem__button:hover { background: rgba(255, 255, 255, .05) !important; color: #fff !important; }
.euiCollapsibleNav .euiListGroupItem-isActive, .euiCollapsibleNav .euiListGroupItem-isActive .euiListGroupItem__button {
  background: rgba(var(--tsoc-accent-rgb), .12) !important; color: var(--tsoc-accent) !important; box-shadow: inset 3px 0 0 var(--tsoc-accent);
}

/* ---------- Superficies ---------- */
.euiPanel, .euiCard, .euiPanel--plain, .euiPageContent.euiPanel {
  background-color: var(--tsoc-surface) !important;
  border-radius: var(--tsoc-radius) !important;
  border: 1px solid var(--tsoc-border) !important;
  box-shadow: var(--tsoc-shadow) !important;
}
.euiPanel .euiPanel, .euiPanel .euiCard { background-color: var(--tsoc-surface-2) !important; box-shadow: none !important; }
.euiPanel.euiPanel--transparent, .euiPanel--transparent { background: transparent !important; border: 0 !important; box-shadow: none !important; }
.euiCard:hover, .euiPanel.euiPanel--isClickable:hover { border-color: rgba(var(--tsoc-accent-rgb), .45) !important; transform: translateY(-1px); transition: all .15s ease; }
.euiFlyout, .euiModal, .euiPopover__panel, .euiContextMenuPanel, .euiToolTip { background-color: var(--tsoc-surface-2) !important; }
.euiFlyout, .euiModal, .euiPopover__panel { border: 1px solid var(--tsoc-border) !important; }
.euiModal, .euiPopover__panel { border-radius: var(--tsoc-radius) !important; box-shadow: 0 16px 40px rgba(0, 0, 0, .5) !important; }
.euiHorizontalRule { background-color: var(--tsoc-border) !important; }
.euiBottomBar { background: var(--tsoc-deep) !important; }

/* ---------- Tablas ---------- */
.euiTable, .euiDataGrid, .euiDataGrid__content { background-color: transparent !important; }
.euiTableHeaderCell .euiTableCellContent__text, .euiTableHeaderCell .euiTableCellContent {
  text-transform: uppercase; font-size: 11px !important; letter-spacing: .05em; color: var(--tsoc-muted) !important; font-weight: 600;
}
.euiTableRow:hover { background-color: rgba(255, 255, 255, .03) !important; }
.euiTableRowCell, .euiTableHeaderCell { border-color: var(--tsoc-border) !important; }

/* ---------- Controles ---------- */
.euiFieldText, .euiFieldSearch, .euiFieldNumber, .euiFieldPassword, .euiSelect, .euiTextArea,
.euiSuperSelectControl, .euiComboBox .euiFormControlLayout__childrenWrapper, .euiFormControlLayout__prepend,
.euiFormControlLayout__append, .euiDatePickerRange, .euiSuperDatePicker__prettyFormat, .euiQuickSelectPopover__anchor {
  background-color: var(--tsoc-input) !important; color: var(--tsoc-text) !important;
}
.euiButton, .euiButtonEmpty, .euiFieldText, .euiFieldSearch, .euiSelect, .euiSuperSelectControl,
.euiComboBox .euiFormControlLayout, .euiFieldNumber, .euiFieldPassword, .euiTextArea, .euiDatePickerRange,
.euiSuperDatePicker, .euiQuickSelectPopover__anchor, .euiFormControlLayout { border-radius: 8px !important; }
.euiButton--primary.euiButton--fill, .euiButton--primary.euiButton--fill:not([disabled]) {
  background: var(--tsoc-primary) !important; border-color: var(--tsoc-primary) !important; color: #fff !important;
}
.euiButton--primary.euiButton--fill:not([disabled]):hover, .euiButton--primary.euiButton--fill:not([disabled]):focus {
  background: var(--tsoc-primary-hover) !important; border-color: var(--tsoc-primary-hover) !important;
}
.euiButton--primary:not(.euiButton--fill) { color: var(--tsoc-accent) !important; border-color: rgba(var(--tsoc-accent-rgb), .55) !important; }
.euiButtonEmpty--primary, .euiButtonIcon--primary, .euiLink.euiLink--primary { color: var(--tsoc-accent) !important; }
.euiTab.euiTab-isSelected, .euiTab-isSelected .euiTab__content { color: var(--tsoc-accent) !important; }
.euiTab.euiTab-isSelected::after { background-color: var(--tsoc-accent) !important; height: 3px !important; border-radius: 3px 3px 0 0; }
.euiSwitch__button[aria-checked="true"] .euiSwitch__body { background-color: var(--tsoc-primary) !important; }
.euiCheckbox__input:checked + .euiCheckbox__square,
.euiRadio__input:checked + .euiRadio__circle { background-color: var(--tsoc-primary) !important; border-color: var(--tsoc-primary) !important; }
.euiProgress--primary::before { background-color: var(--tsoc-accent) !important; }
.euiBadge { border-radius: 999px !important; }

/* ---------- Login ---------- */
.euiPanel.login-wrapper, .login-wrapper .euiPanel {
  border-radius: 16px !important; box-shadow: 0 24px 64px rgba(0, 0, 0, .55) !important;
}
/* Portal de entrada "Cúpula · noche" (triplesoc-login.js añade #tsoc-login, capa fija con la tarjeta, y la clase
   tsoc-login al body). Tarjeta blanca tipo ventana: escena fija en canvas a la izquierda (corte en diagonal) y acceso
   breve a la derecha. Paleta TripleCyber: carbón y neutros; verde y rojo solo como acentos, como en el logo.
   Sin animaciones. El login nativo queda debajo; /app/login#local lo muestra sin el portal. */
body.tsoc-login { overflow: hidden !important; background: #E3E6E5 !important; }
/* Login nativo tapado. Sin display:none ni opacity:0: con la contraseña autocompletada por Chrome eso deja la
   pestaña sin pintar capturas. Plegado = altura 0 + opacity .01 (+ tabindex -1 desde el JS). */
body.tsoc-login .login-wrapper { max-height: 0; overflow: hidden; opacity: .01; pointer-events: none; }
.tsocPortal {
  position: fixed; inset: 0; z-index: 2147482000; display: grid; place-items: center; box-sizing: border-box;
  padding: 32px; overflow-y: auto; font-family: var(--tsoc-font);
  background: radial-gradient(circle at 25% 10%, #F4F5F5 0, #E6E8E7 50%, #D8DBDA 100%);
}
.tsocPortal__card {
  display: grid; grid-template-columns: 1.12fr 1fr; width: min(1080px, 100%); height: min(620px, calc(100vh - 64px));
  min-height: 480px; box-sizing: border-box; padding: 10px; border-radius: 24px; background: #FFFFFF;
  box-shadow: 0 40px 80px -32px rgba(0, 0, 0, .28), 0 2px 6px rgba(0, 0, 0, .05);
}
.tsocPortal__scene {
  position: relative; overflow: hidden; border-radius: 17px; background: #05070b;
  clip-path: polygon(0 0, 100% 0, 91% 100%, 0 100%);
}
.tsocPortal__scene canvas { position: absolute; inset: 0; width: 100%; height: 100%; display: block; }
.tsocPortal__chip {
  position: absolute; left: 20px; bottom: 20px; display: flex; align-items: center; gap: 12px; padding: 10px 18px 10px 10px;
  border-radius: 14px; color: #F1F3F2; background: rgba(10, 12, 14, .5); border: 1px solid rgba(255, 255, 255, .14);
  -webkit-backdrop-filter: blur(14px); backdrop-filter: blur(14px);
}
.tsocPortal__chip svg { width: 36px; height: 36px; flex: 0 0 auto; }
.tsocPortal__chip b { display: block; font: 600 14px/1.25 var(--tsoc-font); }
.tsocPortal__chip span { font-size: 12px; opacity: .75; }
.tsocPortal__auth { display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 32px 40px; }
.tsocPortal__logo { width: 210px; height: auto; margin-bottom: 26px; }
.tsocPortal__hi { margin: 0; font: 700 44px/1.05 var(--tsoc-font); letter-spacing: -.03em; color: #161616; }
.tsocPortal__sub { margin: 8px 0 0; font-size: 16px; color: #5B605E; }
.tsocPortal__does {
  display: flex; align-items: center; gap: 10px; margin: 18px 0 30px;
  font: 500 12px/1 ui-monospace, "Cascadia Mono", Consolas, monospace; letter-spacing: .12em; text-transform: uppercase; color: #3A3D3C;
}
.tsocPortal__does i { display: inline-block; width: 5px; height: 5px; border-radius: 50%; }
.tsocPortal__does i.is-green { background: #1AA54A; }
.tsocPortal__does i.is-red { background: #BB2227; }
.tsocPortal__cta {
  display: inline-flex; align-items: center; justify-content: center; gap: 10px; width: 100%; max-width: 320px; height: 52px;
  border-radius: 12px; background: #161616; color: #fff !important; font: 600 16px/1 var(--tsoc-font);
  text-decoration: none !important; white-space: nowrap; box-shadow: 0 14px 28px -14px rgba(0, 0, 0, .55);
  transition: background .15s;
}
.tsocPortal__cta svg { width: 18px; height: 18px; color: #1AA54A; }
.tsocPortal__cta:hover { background: #262828; }
.tsocPortal__cta:focus-visible { outline: 2px solid #1AA54A; outline-offset: 3px; }
.tsocPortal__cta.is-busy { opacity: .85; pointer-events: none; }
.tsocPortal__legal { margin: 24px 0 0; font: 400 11.5px/1.4 ui-monospace, "Cascadia Mono", Consolas, monospace; color: #8A8F8D; }
@media (max-width: 820px) {
  .tsocPortal { padding: 16px; place-items: start center; }
  .tsocPortal__card { grid-template-columns: 1fr; grid-template-rows: 200px auto; height: auto; min-height: 0; }
  .tsocPortal__scene { clip-path: none; }
  .tsocPortal__chip { display: none; }
  .tsocPortal__auth { padding: 32px 20px 28px; }
  .tsocPortal__hi { font-size: 36px; }
}
/* Base compartida con la pantalla "Access not granted". */
.tsocLogin { display: flex; flex-direction: column; align-items: center; text-align: center; color: #F7F8F7; font-family: var(--tsoc-font); }
.tsocLogin__mark { position: relative; margin-bottom: 26px; }
.tsocLogin__mark::before {
  content: ""; position: absolute; inset: -28px; border-radius: 50%;
  background: radial-gradient(circle, rgba(34, 197, 94, .25) 0, transparent 70%); pointer-events: none;
}
.tsocLogin__mark span {
  position: relative; display: grid; place-items: center; width: 52px; height: 52px; border-radius: 14px;
  background: #1A1F1C; border: 1px solid rgba(34, 197, 94, .35); box-shadow: 0 0 0 6px rgba(34, 197, 94, .06);
}
.tsocLogin__mark img { width: 34px; height: 34px; }
.tsocLogin__title { margin: 0 0 12px; font: 700 34px/1.15 var(--tsoc-font); letter-spacing: -.02em; color: #F7F8F7; }
.tsocLogin__lead { margin: 0 0 28px; max-width: 400px; font-size: 15px; line-height: 1.55; color: #A1AFA9; }
.tsocLogin__card {
  width: 100%; box-sizing: border-box; margin: 0 0 24px; padding: 18px 20px; list-style: none; text-align: left;
  background: #191D1B; border: 1px solid rgba(255, 255, 255, .07); border-radius: 10px;
}
.tsocLogin__primary {
  display: flex; align-items: center; justify-content: center; width: 100%; height: 46px; border-radius: 8px;
  background: #22C55E; color: #04170E !important; font: 600 15px/1 var(--tsoc-font); text-decoration: none !important;
  transition: background .15s, transform .15s, box-shadow .15s;
}
.tsocLogin__primary:hover { background: #2BD468; box-shadow: 0 6px 24px rgba(34, 197, 94, .25); }
.tsocLogin__primary:active { transform: translateY(1px); }
.tsocLogin__primary:focus-visible { outline: 2px solid #86EFAC; outline-offset: 3px; }
.tsocLogin__primary.is-busy { opacity: .8; pointer-events: none; }
.tsocLogin__legal { margin: 28px 0 0; text-align: center; font-size: 12px; color: #66746E; }
/* Puerta de acceso: cuenta sin rol de TripleSOC (triplesoc-login.js). Tapa todo el panel. */
body.tsoc-denied { overflow: hidden !important; }
body.tsoc-denied > *:not(#tsoc-denied) { visibility: hidden !important; }
.tsocDenied {
  position: fixed; inset: 0; z-index: 2147483000; overflow-y: auto; box-sizing: border-box; padding: 72px 20px 40px;
  justify-content: flex-start;
  background: radial-gradient(circle at 50% 18%, rgba(229, 72, 77, .07) 0, rgba(94, 106, 210, .04) 35%, transparent 65%), #121514;
}
.tsocDenied > * { width: 100%; max-width: 440px; }
.tsocDenied > .tsocLogin__mark { width: auto; }
.tsocDenied__mark::before { background: radial-gradient(circle, rgba(229, 72, 77, .22) 0, transparent 70%); }
.tsocDenied__mark span { border-color: rgba(229, 72, 77, .4); box-shadow: 0 0 0 6px rgba(229, 72, 77, .06); }
.tsocDenied__card { display: flex; flex-direction: column; gap: 6px; font-size: 14px; line-height: 1.5; color: #E7ECE9; }
.tsocDenied__card b { color: #F7F8F7; }
.tsocDenied__card i { font-style: normal; color: #22C55E; }
.tsocDenied__card small { margin-top: 6px; font-size: 12px; color: #66746E; font-family: ui-monospace, Consolas, monospace; }
.tsocDenied .tsocLogin__primary { border: 0; cursor: pointer; }
.tsocDenied .tsocLogin__primary:disabled { opacity: .8; cursor: default; }
@media (max-width: 480px) { .tsocLogin__title { font-size: 28px; } }

/* ---------- Sin soporte externo del fabricante ---------- */
[aria-label="Help menu"],
.euiHeaderSectionItem:has([aria-label="Help menu"]),
.euiPopover:has(> .euiPopover__anchor [aria-label="Help menu"]) { display: none !important; }
a[href*="wazuh.com"], a[href*="github.com/wazuh"], a[href*="groups.google.com"],
a[href*="opensearch.org"], a[href*="github.com/opensearch-project"], a[href*="forum.opensearch"],
a[href*="slack.com"], a[href*="elastic.co"] { display: none !important; }
section.euiBottomBar:has(#check-dismiss-in-notification) { display: none !important; }

/* ---------- Menú lateral (estilo del diseño de referencia TripleSOC) ----------
   Mismo menú nativo (mismos enlaces y permisos), solo cambia la presentación.
   Anclado por defecto: parche de core.chrome.isLocked en apply-branding.sh. */
.euiCollapsibleNav { width: 248px !important; min-width: 248px !important; max-width: 248px !important; background: #111111 !important; }
body.euiBody--hasFlyout[style*="padding-left: 320px"] { padding-left: 248px !important; }
.euiCollapsibleNav::before, .euiCollapsibleNav::after { display: block; flex: 0 0 auto; padding-left: 60px; }
.euiCollapsibleNav::before {
  content: "TripleSOC"; order: -2; padding-top: 16px; font: 700 18px/1.2 var(--tsoc-font); color: var(--tsoc-green);
  background: url("/ui/logos/wazuh_mark_on_dark.svg") 16px 14px / 32px 32px no-repeat;
}
.euiCollapsibleNav::after {
  content: "Dashboard"; order: -1; padding-bottom: 14px; margin-bottom: 6px; font: 400 13px/1.3 var(--tsoc-font);
  color: var(--tsoc-muted); border-bottom: 1px solid var(--tsoc-border);
}
.euiCollapsibleNav [data-test-subj="collapsibleNavGroup-recentlyViewed"],
.euiCollapsibleNav [data-test-subj="collapsibleNavGroup-recentlyViewed"] + .euiHorizontalRule { display: none !important; }
.euiCollapsibleNav .euiHorizontalRule { background-color: transparent !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup { border: 0 !important; padding: 0 8px !important; background: transparent !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup .euiAccordion__triggerWrapper { padding: 0 !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__heading {
  min-height: 36px; padding: 7px 10px !important; margin: 1px 0; border-radius: 8px; background: transparent !important;
}
.euiCollapsibleNav .euiCollapsibleNavGroup__heading:hover { background: rgba(255, 255, 255, .05) !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__heading .euiFlexGroup { gap: 10px; margin: 0 !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__heading .euiFlexItem { margin: 0 !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__heading .euiFlexItem--flexGrowZero svg { width: 18px !important; height: 18px !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__title { font: 500 14px/1.3 var(--tsoc-font) !important; color: #D4D4D4 !important; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.euiCollapsibleNav .euiAccordion__iconWrapper { opacity: .55; }
.euiCollapsibleNav .euiCollapsibleNavGroup:has(.euiListGroupItem-isActive) .euiCollapsibleNavGroup__title { color: #fff !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__children { padding: 0 0 6px !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__children .euiListGroupItem { margin: 1px 0 !important; border-radius: 8px; }
.euiCollapsibleNav .euiCollapsibleNavGroup__children .euiListGroupItem__button {
  padding: 6px 10px 6px 38px !important; font: 400 13.5px/1.3 var(--tsoc-font) !important; color: #A3A3A3 !important;
}
.euiCollapsibleNav .euiCollapsibleNavGroup__children .euiListGroupItem:hover { background: rgba(255, 255, 255, .05) !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__children .euiListGroupItem-isActive { background: rgba(var(--tsoc-accent-rgb), .14) !important; box-shadow: none !important; }
.euiCollapsibleNav .euiCollapsibleNavGroup__children .euiListGroupItem-isActive .euiListGroupItem__button { color: var(--tsoc-accent) !important; font-weight: 600 !important; }

/* Entradas propias del menú (overlay/triplesoc-nav.js): selector, accesos, ZONES y usuario al pie */
.tsocNav { padding: 4px 8px 0; font-family: var(--tsoc-font); }
.tsocNav__selector {
  display: flex; align-items: center; gap: 10px; margin: 4px 2px 12px; padding: 9px 12px;
  border: 1px solid var(--tsoc-border); border-radius: 10px; background: #1A1A1A; text-decoration: none !important;
}
.tsocNav__selector:hover { background: #202020; }
.tsocNav__selText { flex: 1; font: 600 13px/1.25 var(--tsoc-font); color: #E5E5E5; }
.tsocNav__selText b { font-weight: 600; }
.tsocNav__chev { width: 16px; height: 16px; color: #737373; }
.tsocNav__item {
  position: relative; display: flex; align-items: center; gap: 10px; min-height: 36px; margin: 1px 0; padding: 7px 10px;
  border-radius: 8px; font: 500 14px/1.3 var(--tsoc-font); color: #D4D4D4 !important; text-decoration: none !important;
}
.tsocNav__item svg { flex: 0 0 18px; width: 18px; height: 18px; color: #A3A3A3; }
.tsocNav__item:hover { background: rgba(255, 255, 255, .05); }
.tsocNav__item--active { background: rgba(var(--tsoc-accent-rgb), .16) !important; color: #fff !important; font-weight: 600; }
.tsocNav__item--active::before { content: ""; position: absolute; left: 0; top: 8px; bottom: 8px; width: 3px; border-radius: 3px; background: var(--tsoc-accent); }
.tsocNav__item--active svg { color: var(--tsoc-accent); }
.tsocNav__label { flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tsocNav__badge {
  min-width: 18px; height: 18px; padding: 0 5px; border-radius: 9px; background: ${TSOC_RED};
  font: 700 11px/18px var(--tsoc-font); color: #fff; text-align: center;
}
.tsocNav__badge[hidden] { display: none; }
.tsocNav__section { padding: 14px 10px 6px; margin-top: 6px; border-top: 1px solid var(--tsoc-border); font: 600 11px/1 var(--tsoc-font); letter-spacing: .08em; text-transform: uppercase; color: #737373; }
.tsocNav__dot { flex: 0 0 8px; width: 8px; height: 8px; margin: 0 5px; border-radius: 50%; }
.tsocNav__dot--red { background: #E5484D; box-shadow: 0 0 0 3px rgba(229, 72, 77, .18); }
.tsocNav__dot--blue { background: #60A5FA; box-shadow: 0 0 0 3px rgba(96, 165, 250, .18); }
.tsocNav__dot--green { background: #22C55E; box-shadow: 0 0 0 3px rgba(34, 197, 94, .18); }
.tsocNav__rule { height: 1px; margin: 10px 2px 6px; background: var(--tsoc-border); }
.tsocNav__user { flex: 0 0 auto; display: flex; align-items: center; gap: 10px; padding: 12px 16px; border-top: 1px solid var(--tsoc-border); background: #111111; }
.tsocNav__user[hidden] { display: none; }
.tsocNav__avatar {
  flex: 0 0 32px; width: 32px; height: 32px; border-radius: 50%; background: rgba(var(--tsoc-accent-rgb), .2);
  font: 700 14px/32px var(--tsoc-font); color: var(--tsoc-accent); text-align: center;
}
.tsocNav__who { display: flex; flex-direction: column; min-width: 0; }
.tsocNav__who b { font: 600 13px/1.3 var(--tsoc-font); color: #fff; }
.tsocNav__who small { font: 400 12px/1.3 var(--tsoc-font); color: var(--tsoc-muted); }
.tsocNav__logout {
  margin-left: auto; flex: 0 0 32px; width: 32px; height: 32px; display: inline-flex; align-items: center; justify-content: center;
  border: 1px solid var(--tsoc-border); border-radius: 8px; background: transparent; color: var(--tsoc-muted); cursor: pointer;
}
.tsocNav__logout:hover, .tsocNav__logout:focus-visible { color: #fff; background: rgba(239, 68, 68, .18); border-color: rgba(239, 68, 68, .5); outline: none; }
.tsocNav__logout:disabled { opacity: .5; cursor: wait; }

/* ---------- Pantalla "Incidents" (overlay/triplesoc-incidents-ui.js) ---------- */
.tsocInc { position: fixed; right: 0; bottom: 0; z-index: 990; display: flex; overflow: hidden; background: #141414; color: #E5E5E5; font: 400 14px/1.4 var(--tsoc-font); }
.tsocInc__page { flex: 1; min-width: 0; overflow: auto; padding: 20px 24px 32px; }
.tsocInc__head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 16px; }
.tsocInc__head h1 { margin: 0; font: 700 26px/1.2 var(--tsoc-font); color: #fff; }
.tsocInc__head p { margin: 4px 0 0; color: var(--tsoc-muted); }
.tsocInc__kpis { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin-bottom: 16px; }
.tsocInc__kpi { padding: 16px 18px; border: 1px solid var(--tsoc-border); border-radius: 12px; background: #1B1B1B; }
.tsocInc__kpiLabel { font: 600 11px/1.3 var(--tsoc-font); letter-spacing: .06em; text-transform: uppercase; color: var(--tsoc-muted); }
.tsocInc__kpiValue { margin-top: 6px; font: 700 30px/1.1 var(--tsoc-font); color: #fff; }
.tsocInc__kpiSub { margin-top: 4px; font-size: 12px; color: var(--tsoc-muted); }
.tsocInc__kpi--red .tsocInc__kpiValue { color: #E5484D; }
.tsocInc__kpi--green .tsocInc__kpiValue { color: #22C55E; }
.tsocInc__kpi--blue .tsocInc__kpiValue { color: #60A5FA; }
.tsocInc__kpi--purple .tsocInc__kpiValue { color: #A78BFA; }
.tsocInc__bar { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 10px; flex-wrap: wrap; }
.tsocInc__tabs { display: flex; gap: 4px; padding: 3px; border: 1px solid var(--tsoc-border); border-radius: 10px; background: #1B1B1B; }
.tsocInc__tabs button { padding: 6px 12px; border: 0; border-radius: 7px; background: transparent; color: #A3A3A3; font: 500 13px/1 var(--tsoc-font); cursor: pointer; }
.tsocInc__tabs button.is-on { background: rgba(var(--tsoc-accent-rgb), .18); color: #fff; }
.tsocInc__bar input { flex: 0 1 340px; min-width: 200px; padding: 8px 12px; border: 1px solid var(--tsoc-border); border-radius: 10px; background: #1B1B1B; color: #fff; font: 400 13px var(--tsoc-font); }
.tsocInc__card { border: 1px solid var(--tsoc-border); border-radius: 12px; background: #1B1B1B; overflow: auto; }
.tsocInc__table, .tsocInc__rules { width: 100%; border-collapse: collapse; }
.tsocInc__table th, .tsocInc__rules th { padding: 10px 12px; text-align: left; font: 600 11px/1.2 var(--tsoc-font); letter-spacing: .05em; text-transform: uppercase; color: #8A8A8A; border-bottom: 1px solid var(--tsoc-border); white-space: nowrap; }
.tsocInc__table td, .tsocInc__rules td { padding: 10px 12px; border-bottom: 1px solid #242424; vertical-align: middle; }
.tsocInc__table tbody tr { cursor: pointer; }
.tsocInc__table tbody tr:hover, .tsocInc__table tbody tr.is-sel { background: rgba(255, 255, 255, .04); }
.tsocInc__table tbody tr.is-sel { box-shadow: inset 3px 0 0 var(--tsoc-accent); }
.tsocInc__title { font-weight: 600; color: #fff; }
.tsocInc__sub { font-size: 12px; color: #8A8A8A; }
.tsocInc__muted { color: #6B6B6B; }
.tsocInc__num { text-align: right !important; font-variant-numeric: tabular-nums; }
.tsocInc__chip { display: inline-block; margin: 1px 4px 1px 0; padding: 2px 7px; border-radius: 6px; background: #262626; font-size: 11px; color: #D4D4D4; white-space: nowrap; }
.tsocInc__ms { margin-left: 6px; padding: 1px 6px; border-radius: 6px; background: rgba(229, 72, 77, .16); color: #E5484D; font: 600 10px/1.6 var(--tsoc-font); text-transform: uppercase; letter-spacing: .04em; }
.tsocInc__sev, .tsocInc__st { display: inline-block; padding: 2px 8px; border-radius: 999px; font: 600 11px/1.6 var(--tsoc-font); text-transform: capitalize; white-space: nowrap; }
.tsocInc__sev--critical { background: rgba(229, 72, 77, .18); color: #F87171; }
.tsocInc__sev--high { background: rgba(245, 158, 11, .18); color: #FBBF24; }
.tsocInc__sev--medium { background: rgba(96, 165, 250, .16); color: #93C5FD; }
.tsocInc__sev--low { background: rgba(34, 197, 94, .14); color: #4ADE80; }
.tsocInc__st--new { background: rgba(229, 72, 77, .14); color: #FCA5A5; }
.tsocInc__st--investigating { background: rgba(245, 158, 11, .14); color: #FCD34D; }
.tsocInc__st--resolved { background: rgba(34, 197, 94, .14); color: #86EFAC; }
.tsocInc__st--false_positive { background: #262626; color: #A3A3A3; }
.tsocInc__empty { display: flex; flex-direction: column; gap: 4px; align-items: center; padding: 48px 16px; color: var(--tsoc-muted); text-align: center; }
.tsocInc__empty b { color: #fff; font-size: 15px; }
.tsocInc__more { padding: 10px 12px; font-size: 12px; color: var(--tsoc-muted); }
.tsocInc__btn { display: inline-flex; align-items: center; padding: 7px 12px; border: 1px solid var(--tsoc-border); border-radius: 8px; background: #222; color: #E5E5E5 !important; font: 600 13px/1.2 var(--tsoc-font); cursor: pointer; text-decoration: none !important; }
.tsocInc__btn:hover { background: #2A2A2A; }
.tsocInc__btn--primary { border-color: transparent; background: ${TSOC_PRIMARY}; color: #fff !important; }
.tsocInc__btn--primary:hover { background: ${TSOC_PRIMARY_HOVER}; }
.tsocInc__btn--ghost { background: transparent; }
.tsocInc__drawer { flex: 0 0 440px; max-width: 46%; display: flex; flex-direction: column; border-left: 1px solid var(--tsoc-border); background: #181818; }
.tsocInc__dHead { display: flex; justify-content: space-between; gap: 12px; padding: 18px 20px 14px; border-bottom: 1px solid var(--tsoc-border); }
.tsocInc__dHead h2 { margin: 8px 0 2px; font: 700 17px/1.3 var(--tsoc-font); color: #fff; }
.tsocInc__x { width: 30px; height: 30px; border: 0; border-radius: 8px; background: #242424; color: #D4D4D4; font-size: 18px; cursor: pointer; }
.tsocInc__dBody { flex: 1; overflow: auto; padding: 14px 20px 24px; }
.tsocInc__dBody h3 { margin: 18px 0 8px; font: 600 12px/1.2 var(--tsoc-font); letter-spacing: .06em; text-transform: uppercase; color: #8A8A8A; }
.tsocInc__meta { display: grid; grid-template-columns: 1fr 1fr; gap: 10px 16px; margin: 0; }
.tsocInc__meta dt { font-size: 11px; color: #8A8A8A; text-transform: uppercase; letter-spacing: .05em; }
.tsocInc__meta dd { margin: 2px 0 0; color: #fff; }
.tsocInc__actions { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 16px; }
.tsocInc__warn { margin-top: 10px; padding: 8px 10px; border-radius: 8px; background: rgba(229, 72, 77, .14); color: #FCA5A5; font-size: 13px; }
.tsocInc__rec { padding: 12px 14px; border: 1px solid var(--tsoc-border); border-radius: 10px; background: #1F1F1F; }
.tsocInc__recTitle { margin-bottom: 4px; font-weight: 600; color: #fff; }
.tsocInc__rec .tsocInc__meta { margin: 10px 0 6px; }
.tsocInc__rec .tsocInc__actions { margin-top: 12px; }
.tsocInc__recState { margin-top: 12px; font-weight: 600; }
.tsocInc__recState--approved { color: #86EFAC; }
.tsocInc__recState--rejected, .tsocInc__recState--failed, .tsocInc__recState--unsupported, .tsocInc__recState--undo_failed { color: #FCA5A5; }
.tsocInc__recState--executed { color: #86EFAC; }
.tsocInc__recState--executing, .tsocInc__recState--undo_requested, .tsocInc__recState--undoing { color: #FCD34D; }
.tsocInc__recState--undone { color: #A3A3A3; }
.tsocInc__recState + .tsocInc__recState { margin-top: 4px; }
.tsocInc__recNote { margin-top: 10px; }
.tsocInc__chain { display: flex; flex-wrap: wrap; gap: 4px; margin: 0; padding: 0; list-style: none; counter-reset: k; }
.tsocInc__chain li { padding: 4px 8px; border-radius: 6px; background: #202020; color: #5E5E5E; font-size: 11px; }
.tsocInc__chain li.on { background: rgba(229, 72, 77, .18); color: #FCA5A5; font-weight: 600; }
.tsocInc__note { display: flex; gap: 8px; align-items: flex-start; }
.tsocInc__note textarea { flex: 1; resize: vertical; padding: 8px 10px; border: 1px solid var(--tsoc-border); border-radius: 8px; background: #1F1F1F; color: #fff; font: 400 13px/1.4 var(--tsoc-font); }
.tsocInc__notes { margin: 10px 0 0; padding: 0; list-style: none; }
.tsocInc__notes li { padding: 8px 0; border-bottom: 1px solid #242424; white-space: pre-wrap; }
@media (max-width: 900px) {
  .tsocInc__kpis { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .tsocInc.has-drawer .tsocInc__page { display: none; }
  .tsocInc__drawer { flex: 1; max-width: none; }
}

/* ---------- Pulido ---------- */
/* Marcador del breadcrumb (Wazuh lo pinta en azul) */
.euiHeader .euiBreadcrumbWall {
  background-image: linear-gradient(to right, var(--tsoc-accent) 0, var(--tsoc-accent) 12px, transparent 12px) !important;
}
/* Máscara tras el menú lateral: neutra en lugar de gris azulado */
.euiOverlayMask { background-color: rgba(0, 0, 0, .6) !important; }
/* Cifras de severidad: respetar el color que Wazuh asigna a cada nivel (el verde de enlace lo tapaba) */
.euiStat__title a.statWithLink, .euiStat__title .euiLink.statWithLink { color: inherit !important; }

/* ---------- Tablero "TripleSOC · Security Overview" (saved-objects/triplesoc-overview.js) ----------
   Solo afecta a ese tablero (data-title del viewport) y a sus paneles por número (panelIndex):
   1 filtros · 2-4 zonas · 5-8 agentes · 9-11 eventos · 12 mapa · 13 línea de tiempo. */
[data-title^="TripleSOC"][data-title$="Security Overview"] { display: flex; flex-direction: column; }
[data-title^="TripleSOC"][data-title$="Security Overview"]::before {
  content: "Security Overview"; order: -2; padding: 20px 16px 2px;
  font: 700 26px/1.2 var(--tsoc-font); color: #fff; letter-spacing: -.01em;
}
[data-title^="TripleSOC"][data-title$="Security Overview"]::after {
  content: attr(data-description); order: -1; padding: 0 16px 8px;
  font: 400 14px/1.4 var(--tsoc-font); color: var(--tsoc-muted);
}
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric {
  background: transparent !important; justify-content: flex-start !important; align-items: stretch !important;
}
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric__resize { position: static !important; width: 100%; height: 100%; }
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric__inner {
  position: static !important; transform: none !important; width: 100%; height: 100%;
  display: flex; flex-direction: column; justify-content: center; align-items: flex-start; text-align: left !important; padding: 0 18px;
}
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric__primary { display: flex; flex-direction: column; align-items: flex-start; width: 100%; }
[data-title^="TripleSOC"][data-title$="Security Overview"] :is(.tvbVisMetric__primary, .tvbVisMetric__secondary) * { text-align: left !important; }
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVis { overflow: hidden !important; }
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric__label--primary {
  font: 600 11px/1.3 var(--tsoc-font) !important; text-transform: uppercase; letter-spacing: .06em;
  color: var(--tsoc-muted) !important; opacity: 1 !important; padding-right: 52px;
}
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric__value--primary {
  font: 700 28px/1.15 var(--tsoc-font) !important; color: #fff !important; margin-top: 4px;
}
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric__secondary { display: flex; align-items: baseline; gap: 8px; margin-top: 6px; }
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric__label--secondary {
  order: 2; font: 400 12px/1.3 var(--tsoc-font) !important; color: var(--tsoc-muted) !important; opacity: 1 !important;
}
[data-title^="TripleSOC"][data-title$="Security Overview"] .tvbVisMetric__value--secondary { font: 700 18px/1.2 var(--tsoc-font) !important; }

/* Icono de cada tarjeta (arriba a la derecha; en las zonas, centrado y más grande) */
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id] .tvbVis { position: relative; }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id] .tvbVisMetric::after {
  content: ""; position: absolute; top: 14px; right: 16px; width: 36px; height: 36px; border-radius: 10px;
  background-repeat: no-repeat; background-position: center; background-size: 20px;
}
/* Zonas: número grande de color, nombre de la zona debajo, icono grande a la derecha */
[data-title^="TripleSOC"][data-title$="Security Overview"] :is([data-test-embeddable-id="2"], [data-test-embeddable-id="3"], [data-test-embeddable-id="4"]) .tvbVisMetric__inner { padding: 0 100px 0 22px; }
[data-title^="TripleSOC"][data-title$="Security Overview"] :is([data-test-embeddable-id="2"], [data-test-embeddable-id="3"], [data-test-embeddable-id="4"]) .tvbVisMetric::after { top: 50%; right: 22px; transform: translateY(-50%); width: 56px; height: 56px; border-radius: 14px; background-size: 30px; }
[data-title^="TripleSOC"][data-title$="Security Overview"] :is([data-test-embeddable-id="2"], [data-test-embeddable-id="3"], [data-test-embeddable-id="4"]) .tvbVisMetric__value--primary { order: -1; font-size: 38px !important; margin: 0 0 2px; }
[data-title^="TripleSOC"][data-title$="Security Overview"] :is([data-test-embeddable-id="2"], [data-test-embeddable-id="3"], [data-test-embeddable-id="4"]) .tvbVisMetric__label--primary { font: 700 16px/1.3 var(--tsoc-font) !important; text-transform: none; letter-spacing: 0; color: #fff !important; padding: 0; }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="2"] :is(.tvbVisMetric__value--primary, .tvbVisMetric__value--secondary) { color: #E5484D !important; }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="3"] :is(.tvbVisMetric__value--primary, .tvbVisMetric__value--secondary) { color: #60A5FA !important; }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="4"] :is(.tvbVisMetric__value--primary, .tvbVisMetric__value--secondary) { color: #22C55E !important; }

[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="2"] .tvbVisMetric::after { background-color: rgba(229, 72, 77, .16); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23E5484D' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z'/%3E%3Cpath d='M12 8v4M12 16h.01'/%3E%3C/svg%3E"); }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="3"] .tvbVisMetric::after { background-color: rgba(96, 165, 250, .16); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%2360A5FA' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='12' cy='12' r='9'/%3E%3Cpath d='m8 12 3 3 5-6'/%3E%3C/svg%3E"); }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="4"] .tvbVisMetric::after { background-color: rgba(34, 197, 94, .16); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%2322C55E' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='5' y='11' width='14' height='10' rx='2'/%3E%3Cpath d='M8 11V7a4 4 0 0 1 8 0v4'/%3E%3C/svg%3E"); }
[data-title^="TripleSOC"][data-title$="Security Overview"] :is([data-test-embeddable-id="5"], [data-test-embeddable-id="11"]) .tvbVisMetric::after { background-color: rgba(139, 92, 246, .16); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23A78BFA' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='4' width='18' height='12' rx='2'/%3E%3Cpath d='M8 20h8M12 16v4'/%3E%3C/svg%3E"); }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="6"] .tvbVisMetric::after { background-color: rgba(34, 197, 94, .16); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%2322C55E' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M2 9a15 15 0 0 1 20 0M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M12 19.5h.01'/%3E%3C/svg%3E"); }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="7"] .tvbVisMetric::after { background-color: rgba(229, 72, 77, .16); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23E5484D' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M2 2l20 20M8.5 16a5 5 0 0 1 7 0M12 19.5h.01M5 12.5a10 10 0 0 1 5-2.7M16.7 10.4a10 10 0 0 1 2.3 2.1'/%3E%3C/svg%3E"); }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="8"] .tvbVisMetric::after { background-color: rgba(217, 119, 6, .18); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23F59E0B' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='12' cy='12' r='9'/%3E%3Cpath d='M12 7v5l3 2'/%3E%3C/svg%3E"); }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="9"] .tvbVisMetric::after { background-color: rgba(229, 72, 77, .16); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23E5484D' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z'/%3E%3C/svg%3E"); }
[data-title^="TripleSOC"][data-title$="Security Overview"] [data-test-embeddable-id="10"] .tvbVisMetric::after { background-color: rgba(96, 165, 250, .16); background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%2360A5FA' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z'/%3E%3Cpath d='M14 2v6h6M8 13h8M8 17h8'/%3E%3C/svg%3E"); }
/* ==== fin TripleSOC ==== */

/* ==== Pantalla AI Rules (overlay/triplesoc-rules-ui.js, reutiliza tsocInc__*) ==== */
.tsocRul__ask { display: flex; flex-direction: column; gap: 6px; margin-bottom: 16px; padding: 14px 16px; }
.tsocRul__ask b { color: #fff; }
.tsocRul__ok { color: #86EFAC; }
.tsocRul__text { color: #D4D4D4; white-space: pre-wrap; }
.tsocRul__checks { margin: 0; padding: 0; list-style: none; }
.tsocRul__check { padding: 6px 0; border-bottom: 1px solid #242424; color: #D4D4D4; font-size: 13px; }
.tsocRul__check.is-ok b { color: #86EFAC; }
.tsocRul__check.is-ko b { color: #FCA5A5; }
.tsocRul__check code { display: block; margin-top: 4px; padding: 6px 8px; border-radius: 6px; background: #111; color: #A3A3A3; font-size: 12px; white-space: pre-wrap; word-break: break-all; }
.tsocRul__pre { margin: 0; padding: 10px 12px; border: 1px solid var(--tsoc-border); border-radius: 8px; background: #111; color: #A5F3FC; font: 12px/1.5 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; white-space: pre-wrap; word-break: break-word; }
.tsocRul__chat { display: flex; flex-direction: column; gap: 8px; margin: 10px 0; padding: 0; list-style: none; }
.tsocRul__msg { max-width: 88%; padding: 8px 10px; border-radius: 10px; background: #1F1F1F; border: 1px solid var(--tsoc-border); }
.tsocRul__msg--user { align-self: flex-end; background: rgba(3, 105, 161, .22); border-color: rgba(3, 105, 161, .5); }
.tsocRul__msg--system { align-self: center; max-width: 100%; background: transparent; border-style: dashed; font-size: 12px; }
.tsocRul__change { margin-top: 6px; padding: 6px 8px; border-radius: 6px; background: rgba(34, 197, 94, .12); color: #BBF7D0; font-size: 12px; }
.tsocRul__typing { color: var(--tsoc-muted); font-style: italic; }

/* ==== Pantalla Guardian (overlay/triplesoc-guardian-ui.js): robot y modo automático ==== */
.tsocGd { --gd: #22C55E; --gd-soft: rgba(34, 197, 94, .14); }
.tsocGd--alert { --gd: #F59E0B; --gd-soft: rgba(245, 158, 11, .16); }
.tsocGd--defending { --gd: #EF4444; --gd-soft: rgba(239, 68, 68, .16); }
.tsocGd__page { max-width: 1180px; margin: 0 auto; }
.tsocGd__hero { display: flex; gap: 28px; align-items: center; padding: 22px 26px; border: 1px solid var(--tsoc-border); border-radius: 18px; background: radial-gradient(circle at 18% 40%, var(--gd-soft), transparent 55%), #181818; }
.tsocGd__botWrap { flex: 0 0 210px; }
.tsocGd__bot { width: 210px; height: 230px; overflow: visible; }
.tsocGd__body { animation: tsocGdFloat 3.2s ease-in-out infinite; transform-origin: 100px 120px; }
.tsocGd__shadow { fill: rgba(0, 0, 0, .45); animation: tsocGdShadow 3.2s ease-in-out infinite; transform-origin: 100px 208px; }
.tsocGd__head, .tsocGd__torso { fill: #E5E7EB; stroke: #9CA3AF; stroke-width: 2; }
.tsocGd__face { fill: #0F172A; }
.tsocGd__eye { fill: var(--gd); filter: drop-shadow(0 0 6px var(--gd)); animation: tsocGdBlink 4.5s infinite; transform-box: fill-box; transform-origin: center; }
.tsocGd__mouth { fill: none; stroke: var(--gd); stroke-width: 4; stroke-linecap: round; }
.tsocGd__scan { fill: var(--gd); opacity: .55; animation: tsocGdScan 2.4s linear infinite; }
.tsocGd__wire { stroke: #9CA3AF; stroke-width: 4; }
.tsocGd__antenna { fill: var(--gd); animation: tsocGdPulse 1.6s ease-in-out infinite; filter: drop-shadow(0 0 8px var(--gd)); }
.tsocGd__shield { fill: var(--gd); opacity: .9; }
.tsocGd__check { fill: none; stroke: #fff; stroke-width: 4; stroke-linecap: round; stroke-linejoin: round; }
.tsocGd__arm { fill: #D1D5DB; }
.tsocGd__arm--r { animation: tsocGdWave 3.2s ease-in-out infinite; transform-origin: 148px 154px; }
.tsocGd--defending .tsocGd__body { animation: tsocGdShake .5s ease-in-out infinite; }
.tsocGd--defending .tsocGd__shield { animation: tsocGdPulse .8s ease-in-out infinite; filter: drop-shadow(0 0 14px var(--gd)); }
.tsocGd--defending .tsocGd__scan { animation-duration: .9s; }
@keyframes tsocGdFloat { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-8px); } }
@keyframes tsocGdShadow { 0%, 100% { transform: scaleX(1); opacity: .6; } 50% { transform: scaleX(.85); opacity: .35; } }
@keyframes tsocGdBlink { 0%, 92%, 100% { transform: scaleY(1); } 95% { transform: scaleY(.1); } }
@keyframes tsocGdScan { 0% { transform: translateY(0); } 100% { transform: translateY(50px); } }
@keyframes tsocGdPulse { 0%, 100% { opacity: 1; } 50% { opacity: .45; } }
@keyframes tsocGdWave { 0%, 70%, 100% { transform: rotate(0); } 80% { transform: rotate(-25deg); } 90% { transform: rotate(10deg); } }
@keyframes tsocGdShake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-3px); } 75% { transform: translateX(3px); } }
@media (prefers-reduced-motion: reduce) { .tsocGd * { animation: none !important; } }
.tsocGd__intro { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 14px; }
.tsocGd__name { font: 700 13px/1 var(--tsoc-font); letter-spacing: .14em; text-transform: uppercase; color: var(--gd); }
.tsocGd__bubble { position: relative; padding: 14px 18px; border-radius: 16px; background: #fff; color: #111827; font: 600 18px/1.4 var(--tsoc-font); max-width: 620px; }
.tsocGd__bubble::before { content: ""; position: absolute; left: -10px; top: 22px; border: 10px solid transparent; border-right-color: #fff; border-left: 0; }
.tsocGd__shieldBar { max-width: 620px; }
.tsocGd__shieldTop { display: flex; justify-content: space-between; color: #E5E5E5; font-weight: 600; }
.tsocGd__shieldTop b { font-size: 20px; color: #fff; }
.tsocGd__meter { height: 12px; margin: 6px 0 4px; border-radius: 99px; background: #2A2A2A; overflow: hidden; }
.tsocGd__meter i { display: block; height: 100%; border-radius: 99px; background: linear-gradient(90deg, #16A34A, #22C55E); transition: width .8s ease; }
.tsocGd__shieldBar--warn .tsocGd__meter i { background: linear-gradient(90deg, #D97706, #F59E0B); }
.tsocGd__shieldBar--bad .tsocGd__meter i { background: linear-gradient(90deg, #DC2626, #EF4444); }
.tsocGd__shieldSub { font-size: 12px; color: var(--tsoc-muted); }
.tsocGd__mode { display: flex; align-items: center; justify-content: space-between; gap: 18px; max-width: 620px; padding: 12px 16px; border-radius: 14px; border: 1px solid var(--tsoc-border); background: #1F1F1F; }
.tsocGd--auto .tsocGd__mode { border-color: rgba(139, 92, 246, .6); background: rgba(139, 92, 246, .12); }
.tsocGd__modeText { display: flex; flex-direction: column; gap: 3px; }
.tsocGd__modeText b { color: #fff; font-size: 15px; }
.tsocGd__modeText span, .tsocGd__modeText small { color: #A3A3A3; font-size: 13px; }
.tsocGd__switch { position: relative; flex: 0 0 auto; width: 112px; height: 44px; border: 0; border-radius: 99px; background: #3F3F46; cursor: pointer; transition: background .25s; }
.tsocGd__switch i { position: absolute; top: 5px; left: 5px; width: 34px; height: 34px; border-radius: 50%; background: #fff; box-shadow: 0 2px 6px rgba(0, 0, 0, .4); transition: left .25s; }
.tsocGd__switch.is-on { background: linear-gradient(90deg, #7C3AED, #A855F7); box-shadow: 0 0 18px rgba(168, 85, 247, .55); }
.tsocGd__switch.is-on i { left: 73px; }
.tsocGd__switchLbl { position: absolute; top: 50%; transform: translateY(-50%); right: 14px; font: 800 12px/1 var(--tsoc-font); letter-spacing: .08em; color: #E5E5E5; }
.tsocGd__switch.is-on .tsocGd__switchLbl { right: auto; left: 14px; color: #fff; }
.tsocGd__kpis { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 12px; margin: 16px 0; }
.tsocGd__kpi { display: flex; gap: 12px; align-items: center; padding: 14px; border-radius: 14px; border: 1px solid var(--tsoc-border); background: #181818; }
.tsocGd__kpiIcon { display: grid; place-items: center; flex: 0 0 44px; height: 44px; border-radius: 12px; font-size: 22px; background: #242424; }
.tsocGd__kpi--green .tsocGd__kpiIcon { background: rgba(34, 197, 94, .16); }
.tsocGd__kpi--blue .tsocGd__kpiIcon { background: rgba(59, 130, 246, .16); }
.tsocGd__kpi--purple .tsocGd__kpiIcon { background: rgba(139, 92, 246, .16); }
.tsocGd__kpi--cyan .tsocGd__kpiIcon { background: rgba(34, 211, 238, .16); }
.tsocGd__kpi--amber .tsocGd__kpiIcon { background: rgba(245, 158, 11, .16); }
.tsocGd__kpiValue { font: 800 24px/1.1 var(--tsoc-font); color: #fff; }
.tsocGd__kpiLabel { font-size: 13px; font-weight: 600; color: #E5E5E5; }
.tsocGd__kpiSub { font-size: 11px; color: var(--tsoc-muted); }
.tsocGd__feed { padding: 16px 18px; }
.tsocGd__feedHead { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.tsocGd__feedHead h2 { margin: 0; font: 700 18px/1.2 var(--tsoc-font); color: #fff; }
.tsocGd__feed ul { margin: 0; padding: 0; list-style: none; }
.tsocGd__story { display: flex; gap: 14px; padding: 14px 4px; border-bottom: 1px solid #242424; }
.tsocGd__storyIcon { display: grid; place-items: center; flex: 0 0 46px; height: 46px; border-radius: 50%; font-size: 22px; background: rgba(34, 197, 94, .14); }
.tsocGd__story--warn .tsocGd__storyIcon { background: rgba(245, 158, 11, .16); }
.tsocGd__story--muted .tsocGd__storyIcon { background: #242424; }
.tsocGd__storyBody { flex: 1; min-width: 0; }
.tsocGd__storyHead { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; color: #A3A3A3; font-size: 12px; }
.tsocGd__storyHead b { color: #fff; font-size: 14px; }
.tsocGd__story p { margin: 6px 0 8px; color: #E5E5E5; font-size: 15px; line-height: 1.5; }
.tsocGd__storyActions { display: flex; gap: 8px; }
.tsocGd__tag { padding: 2px 8px; border-radius: 99px; background: rgba(139, 92, 246, .18); color: #DDD6FE; font-size: 11px; font-weight: 600; }
.tsocGd__tag--human { background: rgba(34, 197, 94, .16); color: #BBF7D0; }
@media (max-width: 1100px) { .tsocGd__kpis { grid-template-columns: repeat(2, minmax(0, 1fr)); } .tsocGd__hero { flex-direction: column; align-items: stretch; } .tsocGd__botWrap { align-self: center; } }

/* ==== Asistente Guardian (overlay/triplesoc-assistant.js): robot holográfico en todas las pantallas ==== */
.tsocAs { --as-c: #22D3EE; --as-c2: #6366F1; position: fixed; right: 22px; bottom: 20px; z-index: 1001; font: 400 14px/1.45 var(--tsoc-font); color: #E5E7EB; transition: right .3s ease; }
.tsocAs[data-state="thinking"] { --as-c: #A78BFA; --as-c2: #EC4899; }
.tsocAs[data-state="speaking"] { --as-c: #34D399; --as-c2: #22D3EE; }
.tsocAs[data-state="listening"] { --as-c: #F472B6; --as-c2: #A78BFA; }
.tsocAs[data-state="alert"] { --as-c: #FBBF24; --as-c2: #F97316; }
.tsocAs[data-state="defending"] { --as-c: #F87171; --as-c2: #EF4444; }

/* Robot */
.tsocAs__bot { display: block; overflow: visible; }
.tsocAs__float { animation: tsocAsFloat 3.4s ease-in-out infinite; transform-origin: 60px 60px; }
.tsocAs__aura { animation: tsocAsAura 3.4s ease-in-out infinite; transform-origin: 60px 62px; }
.tsocAs__ant { fill: var(--as-c); filter: drop-shadow(0 0 5px var(--as-c)); animation: tsocAsBlinkAnt 1.8s ease-in-out infinite; }
.tsocAs__eyes { transition: transform .12s ease-out; }
.tsocAs__eye { fill: var(--as-c); filter: drop-shadow(0 0 4px var(--as-c)); animation: tsocAsBlink 5s infinite; transform-box: fill-box; transform-origin: center; }
.tsocAs__mouth rect { fill: var(--as-c); opacity: .85; transform-box: fill-box; transform-origin: center; }
.tsocAs__scan { fill: var(--as-c); opacity: .45; animation: tsocAsScan 2.6s linear infinite; }
.tsocAs[data-state="speaking"] .tsocAs__mouth rect, .tsocGd .tsocAs__mouth rect.is-talk { animation: tsocAsTalk .45s ease-in-out infinite; }
.tsocAs[data-state="speaking"] .tsocAs__mouth rect:nth-child(2n) { animation-delay: .12s; }
.tsocAs[data-state="speaking"] .tsocAs__mouth rect:nth-child(3) { animation-delay: .24s; }
.tsocAs[data-state="thinking"] .tsocAs__eye { animation: tsocAsThink 1.2s ease-in-out infinite; }
.tsocAs[data-state="defending"] .tsocAs__float { animation: tsocAsShake .45s ease-in-out infinite; }
@keyframes tsocAsFloat { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-4px); } }
@keyframes tsocAsAura { 0%, 100% { transform: scale(.92); opacity: .7; } 50% { transform: scale(1.05); opacity: 1; } }
@keyframes tsocAsBlinkAnt { 0%, 100% { opacity: 1; } 50% { opacity: .35; } }
@keyframes tsocAsBlink { 0%, 93%, 100% { transform: scaleY(1); } 96% { transform: scaleY(.12); } }
@keyframes tsocAsScan { 0% { transform: translateY(0); opacity: 0; } 15% { opacity: .5; } 100% { transform: translateY(40px); opacity: 0; } }
@keyframes tsocAsTalk { 0%, 100% { transform: scaleY(1); } 50% { transform: scaleY(2.6); } }
@keyframes tsocAsThink { 0%, 100% { transform: scaleY(1) translateX(0); } 50% { transform: scaleY(.55) translateX(1.5px); } }
@keyframes tsocAsShake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-1.5px); } 75% { transform: translateX(1.5px); } }

/* Lanzador (orbe) */
.tsocAs__launcher { position: relative; display: grid; place-items: center; width: 74px; height: 74px; padding: 0; border: 1px solid rgba(255, 255, 255, .14); border-radius: 50%; cursor: pointer;
  background: radial-gradient(circle at 35% 30%, rgba(255, 255, 255, .16), rgba(15, 23, 42, .92) 62%); box-shadow: 0 12px 30px rgba(0, 0, 0, .55), 0 0 24px color-mix(in srgb, var(--as-c) 45%, transparent), inset 0 0 18px rgba(255, 255, 255, .06);
  transition: transform .25s cubic-bezier(.2, .9, .3, 1.4), box-shadow .3s; }
.tsocAs__launcher:hover { transform: translateY(-3px) scale(1.06); }
.tsocAs__launcher:focus-visible { outline: 2px solid var(--as-c); outline-offset: 4px; }
.tsocAs__bot--orb { width: 62px; height: 62px; }
.tsocAs__ring { position: absolute; inset: -6px; border-radius: 50%; border: 1.5px solid var(--as-c); opacity: 0; animation: tsocAsRing 3s ease-out infinite; pointer-events: none; }
.tsocAs__ring--2 { animation-delay: 1.5s; }
.tsocAs[data-state="defending"] .tsocAs__ring, .tsocAs[data-state="alert"] .tsocAs__ring { animation-duration: 1.2s; }
@keyframes tsocAsRing { 0% { transform: scale(.9); opacity: .65; } 100% { transform: scale(1.45); opacity: 0; } }
.tsocAs__badge { position: absolute; top: -2px; right: -2px; min-width: 22px; height: 22px; padding: 0 6px; border-radius: 99px; background: linear-gradient(135deg, #F43F5E, #EC4899); color: #fff; font: 700 12px/22px var(--tsoc-font); box-shadow: 0 0 0 3px #0B0F17; }
.tsocAs.is-open .tsocAs__launcher { transform: scale(.88); }

/* Burbuja de presentación */
.tsocAs__bubble { position: absolute; right: 6px; bottom: 90px; width: 330px; padding: 14px 16px 12px; border-radius: 18px 18px 6px 18px;
  background: linear-gradient(160deg, rgba(30, 41, 59, .92), rgba(15, 23, 42, .94)); border: 1px solid rgba(255, 255, 255, .12);
  box-shadow: 0 20px 50px rgba(0, 0, 0, .55), 0 0 0 1px color-mix(in srgb, var(--as-c) 25%, transparent); backdrop-filter: blur(16px) saturate(150%); -webkit-backdrop-filter: blur(16px) saturate(150%); }
.tsocAs__bubble.is-in { animation: tsocAsPop .45s cubic-bezier(.2, .9, .3, 1.25) both; }
.tsocAs__bubble p { margin: 0 18px 8px 0; color: #F1F5F9; font-size: 14.5px; }
.tsocAs__bx { position: absolute; top: 8px; right: 8px; width: 24px; height: 24px; border: 0; border-radius: 8px; background: rgba(255, 255, 255, .06); color: #94A3B8; cursor: pointer; }
@keyframes tsocAsPop { from { opacity: 0; transform: translateY(12px) scale(.94); } to { opacity: 1; transform: none; } }

/* Panel de conversación */
.tsocAs__panel { position: absolute; right: 0; bottom: 92px; display: flex; flex-direction: column; width: min(410px, calc(100vw - 40px)); height: min(620px, calc(100vh - 140px));
  border-radius: 24px; overflow: hidden; background: linear-gradient(170deg, rgba(17, 24, 39, .86), rgba(8, 12, 22, .92));
  border: 1px solid rgba(255, 255, 255, .1); box-shadow: 0 30px 80px rgba(0, 0, 0, .65), 0 0 0 1px color-mix(in srgb, var(--as-c) 22%, transparent), 0 0 60px color-mix(in srgb, var(--as-c) 12%, transparent);
  backdrop-filter: blur(22px) saturate(160%); -webkit-backdrop-filter: blur(22px) saturate(160%); animation: tsocAsPanel .38s cubic-bezier(.2, .9, .3, 1.15) both; }
.tsocAs__panel[hidden] { display: none; }
@keyframes tsocAsPanel { from { opacity: 0; transform: translateY(18px) scale(.96); } to { opacity: 1; transform: none; } }
.tsocAs__panel::before { content: ""; position: absolute; inset: 0 0 auto 0; height: 2px; background: linear-gradient(90deg, transparent, var(--as-c), var(--as-c2), transparent); animation: tsocAsLine 3s linear infinite; background-size: 200% 100%; }
@keyframes tsocAsLine { from { background-position: 0 0; } to { background-position: 200% 0; } }
.tsocAs__head { display: flex; align-items: center; gap: 12px; padding: 14px 14px 12px 16px; border-bottom: 1px solid rgba(255, 255, 255, .07);
  background: radial-gradient(circle at 12% 50%, color-mix(in srgb, var(--as-c) 18%, transparent), transparent 60%); }
.tsocAs__headBot { flex: 0 0 48px; height: 48px; display: grid; place-items: center; border-radius: 16px; background: rgba(255, 255, 255, .04); border: 1px solid rgba(255, 255, 255, .08); }
.tsocAs__bot--mini { width: 44px; height: 44px; }
.tsocAs__headText { flex: 1; display: flex; flex-direction: column; min-width: 0; }
.tsocAs__headText b { font: 700 16px/1.2 var(--tsoc-font); color: #fff; letter-spacing: .01em; }
.tsocAs__headText span { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #94A3B8; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tsocAs__headText span i { width: 8px; height: 8px; border-radius: 50%; background: var(--as-c); box-shadow: 0 0 8px var(--as-c); animation: tsocAsBlinkAnt 1.6s infinite; }
.tsocAs__icon { width: 34px; height: 34px; border: 0; border-radius: 10px; background: rgba(255, 255, 255, .05); color: #CBD5E1; font-size: 15px; cursor: pointer; }
.tsocAs__icon:hover { background: rgba(255, 255, 255, .1); }
.tsocAs__msgs { flex: 1; overflow-y: auto; padding: 16px 14px 8px; display: flex; flex-direction: column; gap: 12px; scrollbar-width: thin; scrollbar-color: #334155 transparent; }
.tsocAs__msg { display: flex; gap: 8px; align-items: flex-end; animation: tsocAsPop .35s ease both; }
.tsocAs__msg--me { justify-content: flex-end; }
.tsocAs__msgBot { flex: 0 0 30px; height: 30px; }
.tsocAs__bot--tiny { width: 30px; height: 30px; }
.tsocAs__msgBody { max-width: 82%; padding: 10px 13px; border-radius: 16px 16px 16px 4px; background: rgba(255, 255, 255, .06); border: 1px solid rgba(255, 255, 255, .07); }
.tsocAs__msgBody p { margin: 0; white-space: pre-wrap; color: #E2E8F0; }
.tsocAs__msg--me .tsocAs__msgBody { border-radius: 16px 16px 4px 16px; background: linear-gradient(135deg, color-mix(in srgb, var(--as-c2) 70%, #1E293B), color-mix(in srgb, var(--as-c) 55%, #1E293B)); border-color: transparent; }
.tsocAs__msg--me .tsocAs__msgBody p { color: #fff; }
.tsocAs__sugs { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 9px; }
.tsocAs__sug { padding: 6px 11px; border-radius: 99px; border: 1px solid color-mix(in srgb, var(--as-c) 55%, transparent); background: color-mix(in srgb, var(--as-c) 12%, transparent); color: #F1F5F9; font: 600 12.5px/1.2 var(--tsoc-font); cursor: pointer; transition: background .2s, transform .2s; }
.tsocAs__sug:hover { background: color-mix(in srgb, var(--as-c) 26%, transparent); transform: translateY(-1px); }
.tsocAs__dots { display: flex; gap: 5px; align-items: center; padding: 14px 16px; }
.tsocAs__dots i { width: 7px; height: 7px; border-radius: 50%; background: var(--as-c); animation: tsocAsDot 1.1s ease-in-out infinite; }
.tsocAs__dots i:nth-child(2) { animation-delay: .15s; } .tsocAs__dots i:nth-child(3) { animation-delay: .3s; }
@keyframes tsocAsDot { 0%, 100% { transform: translateY(0); opacity: .4; } 50% { transform: translateY(-5px); opacity: 1; } }
.tsocAs__chips { display: flex; gap: 6px; padding: 4px 14px 10px; overflow-x: auto; scrollbar-width: none; }
.tsocAs__chips[hidden] { display: none; }
.tsocAs__chip { flex: 0 0 auto; padding: 7px 12px; border-radius: 99px; border: 1px solid rgba(255, 255, 255, .1); background: rgba(255, 255, 255, .04); color: #CBD5E1; font: 500 12.5px/1 var(--tsoc-font); cursor: pointer; }
.tsocAs__chip:hover { border-color: var(--as-c); color: #fff; }
.tsocAs__input { display: flex; gap: 8px; align-items: center; margin: 0 12px 8px; padding: 6px; border-radius: 16px; background: rgba(0, 0, 0, .35); border: 1px solid rgba(255, 255, 255, .09); }
.tsocAs__input:focus-within { border-color: color-mix(in srgb, var(--as-c) 60%, transparent); box-shadow: 0 0 0 3px color-mix(in srgb, var(--as-c) 15%, transparent); }
.tsocAs__input input { flex: 1; min-width: 0; border: 0; outline: 0; background: transparent; color: #F8FAFC; font: 400 14px/1.4 var(--tsoc-font); }
.tsocAs__input input::placeholder { color: #64748B; }
.tsocAs__mic, .tsocAs__send { flex: 0 0 38px; height: 38px; border: 0; border-radius: 12px; cursor: pointer; display: grid; place-items: center; }
.tsocAs__mic { position: relative; background: rgba(255, 255, 255, .06); }
.tsocAs__mic span { width: 12px; height: 18px; border-radius: 6px; border: 2px solid #CBD5E1; position: relative; }
.tsocAs__mic span::after { content: ""; position: absolute; left: 50%; bottom: -7px; width: 14px; height: 7px; transform: translateX(-50%); border: 2px solid #CBD5E1; border-top: 0; border-radius: 0 0 8px 8px; }
.tsocAs[data-state="listening"] .tsocAs__mic { background: color-mix(in srgb, var(--as-c) 30%, transparent); box-shadow: 0 0 0 0 var(--as-c); animation: tsocAsMic 1.2s infinite; }
@keyframes tsocAsMic { 0% { box-shadow: 0 0 0 0 color-mix(in srgb, var(--as-c) 60%, transparent); } 100% { box-shadow: 0 0 0 12px transparent; } }
.tsocAs__send { background: linear-gradient(135deg, var(--as-c2), var(--as-c)); color: #fff; font-size: 15px; box-shadow: 0 6px 16px color-mix(in srgb, var(--as-c) 35%, transparent); }
.tsocAs__foot { padding: 0 16px 12px; font-size: 11px; color: #64748B; text-align: center; }

/* Pantalla Guardian: el mismo robot, en grande, sobre una base holográfica */
.tsocGd__holo { position: relative; width: 230px; height: 240px; display: grid; place-items: center; }
.tsocGd .tsocAs__bot--hero { --as-c: var(--gd); width: 210px; height: 210px; position: relative; z-index: 2; filter: drop-shadow(0 18px 30px rgba(0, 0, 0, .5)); }
.tsocGd__orbit { position: absolute; left: 50%; top: 50%; width: 220px; height: 70px; margin: -10px 0 0 -110px; border-radius: 50%; border: 1.5px solid var(--gd); opacity: .35; transform: rotateX(70deg); animation: tsocGdOrbit 6s linear infinite; }
.tsocGd__orbit--2 { width: 180px; height: 56px; margin-left: -90px; opacity: .25; animation-duration: 9s; animation-direction: reverse; }
@keyframes tsocGdOrbit { from { transform: rotateX(70deg) rotateZ(0); } to { transform: rotateX(70deg) rotateZ(360deg); } }
.tsocGd__base { position: absolute; bottom: 4px; left: 50%; width: 150px; height: 24px; margin-left: -75px; border-radius: 50%; background: radial-gradient(ellipse, var(--gd), transparent 70%); opacity: .45; filter: blur(4px); animation: tsocAsAura 3.4s ease-in-out infinite; }
.tsocGd--defending .tsocAs__float { animation: tsocAsShake .45s ease-in-out infinite; }
.tsocGd__switch { width: 124px; }
.tsocGd__switch.is-on i { left: 85px; }
@media (max-width: 640px) { .tsocAs__bubble { width: calc(100vw - 60px); } }
@media (prefers-reduced-motion: reduce) { .tsocAs *, .tsocGd__holo * { animation: none !important; } }

/* ---- Respuesta en directo (carril rápido): traza paso a paso con tiempos medidos ---- */
.tsocGd__live { padding: 16px 18px; margin-bottom: 16px; overflow: hidden; }
.tsocLv__head { flex-wrap: wrap; gap: 8px 16px; }
.tsocLv__laneWrap { display: flex; flex-wrap: wrap; align-items: center; gap: 6px 12px; font: 500 12px/1.3 var(--tsoc-font); color: #94A3B8; }
.tsocLv__lane { display: inline-flex; align-items: center; gap: 7px; padding: 4px 10px; border-radius: 99px; border: 1px solid rgba(52, 211, 153, .35); background: rgba(52, 211, 153, .1); color: #A7F3D0; font-weight: 600; }
.tsocLv__lane i { width: 7px; height: 7px; border-radius: 50%; background: #34D399; box-shadow: 0 0 0 0 rgba(52, 211, 153, .6); animation: tsocLvPulse 1.8s ease-out infinite; }
.tsocLv__lane--off { border-color: rgba(148, 163, 184, .35); background: rgba(148, 163, 184, .1); color: #CBD5E1; }
.tsocLv__lane--off i { background: #94A3B8; animation: none; }
.tsocLv__laneInfo { font-variant-numeric: tabular-nums; }
.tsocLv { --lv-c: #94A3B8; margin-top: 10px; padding: 14px 16px 12px; border-radius: 12px; border: 1px solid color-mix(in srgb, var(--lv-c) 28%, transparent); background: linear-gradient(180deg, color-mix(in srgb, var(--lv-c) 7%, #151515), #151515 70%); }
.tsocLv--ok { --lv-c: #34D399; } .tsocLv--warn { --lv-c: #FBBF24; } .tsocLv--bad { --lv-c: #F87171; } .tsocLv--muted { --lv-c: #94A3B8; }
.tsocLv__top { display: flex; align-items: center; gap: 12px; min-width: 0; }
.tsocLv__state { display: inline-flex; align-items: center; gap: 7px; flex: none; font: 700 12px/1 var(--tsoc-font); letter-spacing: .04em; text-transform: uppercase; color: var(--lv-c); }
.tsocLv__state i { width: 8px; height: 8px; border-radius: 50%; background: var(--lv-c); box-shadow: 0 0 8px var(--lv-c); }
.tsocLv__host { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #CBD5E1; font: 500 13px/1.2 var(--tsoc-font); }
.tsocLv__total { flex: none; color: #fff; font: 700 26px/1 ui-monospace, "SF Mono", Consolas, monospace; font-variant-numeric: tabular-nums; letter-spacing: -.02em; }
.tsocLv__steps { display: grid; grid-template-columns: repeat(var(--n, 5), minmax(0, 1fr)); margin: 16px 0 4px; padding: 0; list-style: none; }
.tsocLv__step { position: relative; display: grid; grid-template-rows: 18px 14px auto; row-gap: 6px; padding-right: 12px; min-width: 0; }
.tsocLv__step::before { content: ""; position: absolute; top: 30px; left: 0; right: 0; height: 2px; background: color-mix(in srgb, var(--lv-c) 45%, transparent); transform-origin: left; }
.tsocLv__step:last-child::before { right: auto; width: 12px; opacity: .4; }
.tsocLv__t { color: var(--lv-c); font: 600 12px/18px ui-monospace, "SF Mono", Consolas, monospace; font-variant-numeric: tabular-nums; white-space: nowrap; }
.tsocLv__dot { position: relative; z-index: 1; width: 14px; height: 14px; border-radius: 50%; background: #151515; border: 2px solid var(--lv-c); box-shadow: 0 0 0 3px #151515; }
.tsocLv__step--act .tsocLv__dot, .tsocLv__step--verify .tsocLv__dot { background: var(--lv-c); }
.tsocLv__txt { min-width: 0; }
.tsocLv__txt b { display: block; color: #F1F5F9; font: 600 13px/1.25 var(--tsoc-font); }
.tsocLv__txt small { display: block; margin-top: 2px; color: #94A3B8; font: 400 11.5px/1.35 var(--tsoc-font); overflow-wrap: anywhere; }
.tsocLv__chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }
.tsocLv__chips span { padding: 2px 8px; border-radius: 6px; border: 1px solid rgba(255, 255, 255, .1); background: rgba(255, 255, 255, .04); color: #CBD5E1; font: 500 11px/1.5 ui-monospace, "SF Mono", Consolas, monospace; }
.tsocLv__note { margin: 10px 2px 0; color: #64748B; font: 400 11.5px/1.4 var(--tsoc-font); }
.tsocLv__hist { margin: 12px 0 0; padding: 0; list-style: none; border-top: 1px solid var(--tsoc-border); }
.tsocLv__row { display: flex; align-items: center; gap: 12px; padding: 8px 2px; border-bottom: 1px solid var(--tsoc-border); }
.tsocLv__row .tsocLv__state { width: 210px; font-size: 11px; }
.tsocLv__row .tsocLv__total { font-size: 14px; min-width: 70px; text-align: right; }
.tsocLv__when { flex: none; color: #64748B; font-size: 12px; }
/* Compacta (tarjeta del asistente): pasos en vertical. */
.tsocLv--compact { margin-top: 6px; padding: 10px 12px; }
.tsocLv--compact .tsocLv__top { flex-wrap: wrap; gap: 6px 10px; }
.tsocLv--compact .tsocLv__host { flex-basis: 100%; order: 3; font-size: 12px; }
.tsocLv--compact .tsocLv__state { flex: 1; font-size: 11px; }
.tsocLv--compact .tsocLv__total { font-size: 20px; }
.tsocLv--compact .tsocLv__steps { grid-template-columns: 1fr; margin: 10px 0 0; }
.tsocLv--compact .tsocLv__step { grid-template-rows: none; grid-template-columns: 62px 14px minmax(0, 1fr); column-gap: 8px; row-gap: 0; align-items: start; padding: 0 0 9px; }
.tsocLv--compact .tsocLv__step::before { top: 14px; bottom: 0; left: 76px; right: auto; width: 2px; height: auto; transform-origin: top; }
.tsocLv--compact .tsocLv__step:last-child::before { display: none; }
.tsocLv--compact .tsocLv__t { text-align: right; font-size: 11px; }
.tsocLv--compact .tsocLv__dot { margin-top: 2px; }
.tsocLv--compact .tsocLv__txt b { font-size: 12.5px; }
.tsocLv--compact .tsocLv__txt small { font-size: 11px; }
.tsocAs__bubble--live { width: 372px; }
/* ---- Isla: el Guardian siempre a la vista, arriba al centro; se despliega cuando pasa algo ---- */
.tsocIs { --lv-c: #94A3B8; position: fixed; top: 7px; left: 50%; transform: translateX(-50%); z-index: 1002; width: max-content; max-width: min(520px, calc(100vw - 24px)); font: 400 13px/1.4 var(--tsoc-font); color: #E5E7EB;
  border-radius: 18px; background: rgba(10, 12, 16, .94); border: 1px solid rgba(255, 255, 255, .1); box-shadow: 0 6px 22px rgba(0, 0, 0, .5), 0 0 0 1px color-mix(in srgb, var(--lv-c) 22%, transparent);
  backdrop-filter: blur(14px) saturate(140%); -webkit-backdrop-filter: blur(14px) saturate(140%); transition: border-radius .2s ease, box-shadow .25s ease; }
.tsocIs--ok { --lv-c: #34D399; } .tsocIs--warn { --lv-c: #FBBF24; } .tsocIs--bad { --lv-c: #F87171; } .tsocIs--muted { --lv-c: #94A3B8; }
.tsocIs.is-open { width: min(520px, calc(100vw - 24px)); box-shadow: 0 24px 70px rgba(0, 0, 0, .7), 0 0 0 1px color-mix(in srgb, var(--lv-c) 35%, transparent), 0 0 44px color-mix(in srgb, var(--lv-c) 14%, transparent); }
.tsocIs__pill { display: flex; align-items: center; gap: 9px; width: 100%; height: 34px; padding: 0 12px 0 13px; border: 0; background: none; color: inherit; font: inherit; cursor: pointer; white-space: nowrap; }
.tsocIs__pill:focus-visible { outline: 2px solid var(--lv-c); outline-offset: 2px; border-radius: 18px; }
.tsocIs__dot { flex: none; width: 8px; height: 8px; border-radius: 50%; background: var(--lv-c); box-shadow: 0 0 0 0 color-mix(in srgb, var(--lv-c) 60%, transparent); animation: tsocIsPulse 2s ease-out infinite; }
.tsocIs--muted .tsocIs__dot { animation: none; }
.tsocIs--warn .tsocIs__dot, .tsocIs--bad .tsocIs__dot { animation-duration: .9s; }
.tsocIs__pill b { font-weight: 700; color: #fff; letter-spacing: .01em; }
.tsocIs__line { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; color: #CBD5E1; font-variant-numeric: tabular-nums; text-align: left; }
.tsocIs__mode { flex: none; padding: 1px 7px; border-radius: 6px; border: 1px solid rgba(255, 255, 255, .14); color: #CBD5E1; font: 700 10px/1.6 ui-monospace, "SF Mono", Consolas, monospace; letter-spacing: .06em; font-style: normal; }
.tsocIs__chev { flex: none; color: #64748B; font-size: 11px; transition: transform .2s ease; }
.tsocIs.is-open .tsocIs__chev { transform: rotate(180deg); }
.tsocIs__body { padding: 2px 12px 12px; max-height: min(72vh, 640px); overflow: auto; border-top: 1px solid rgba(255, 255, 255, .07); animation: tsocLvIn .22s ease-out both; }
.tsocIs__tabs { display: flex; align-items: center; gap: 4px; margin: 8px 0 4px; }
.tsocIs__tabs button { padding: 4px 11px; border-radius: 8px; border: 0; background: none; color: #94A3B8; font: 600 12px/1.4 var(--tsoc-font); cursor: pointer; }
.tsocIs__tabs button.is-on { background: rgba(255, 255, 255, .09); color: #fff; }
.tsocIs__tabs a { margin-left: auto; color: #94A3B8; font-size: 12px; text-decoration: none; }
.tsocIs__tabs a:hover { color: #fff; text-decoration: underline; }
.tsocIs__sub { margin: 10px 2px 4px; color: #94A3B8; font: 600 11px/1.4 var(--tsoc-font); letter-spacing: .06em; text-transform: uppercase; }
.tsocIs__body > .tsocIs__sub:only-of-type { text-transform: none; letter-spacing: 0; font-weight: 400; font-size: 12.5px; }
.tsocIs__note { margin: 8px 0 0; padding: 7px 10px; border-radius: 8px; background: rgba(255, 255, 255, .06); color: #E2E8F0; font-size: 12.5px; }
.tsocIs__ask { margin-top: 6px; padding: 12px; border-radius: 12px; border: 1px solid rgba(251, 191, 36, .35); background: rgba(251, 191, 36, .07); }
.tsocIs__askTxt b { display: block; color: #fff; font: 700 14px/1.3 var(--tsoc-font); }
.tsocIs__askTxt span { display: block; margin-top: 2px; color: #CBD5E1; font: 500 11.5px/1.4 ui-monospace, "SF Mono", Consolas, monospace; }
.tsocIs__askTxt p { margin: 8px 0 0; color: #CBD5E1; font-size: 12.5px; }
.tsocIs__askBtns { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-top: 12px; }
.tsocIs__askBtns button { height: 34px; border-radius: 10px; border: 1px solid rgba(255, 255, 255, .16); background: rgba(255, 255, 255, .06); color: #F1F5F9; font: 700 13px/1 var(--tsoc-font); cursor: pointer; }
.tsocIs__askBtns button:hover { background: rgba(255, 255, 255, .12); }
.tsocIs__askBtns button:disabled { opacity: .5; cursor: default; }
.tsocIs__askBtns .tsocIs__allow { border-color: transparent; background: #34D399; color: #052E1B; }
.tsocIs__askBtns .tsocIs__allow:hover { background: #6EE7B7; }
.tsocIs__kv { width: 100%; border-collapse: collapse; font: 400 11.5px/1.5 ui-monospace, "SF Mono", Consolas, monospace; }
.tsocIs__kv th { width: 132px; padding: 2px 10px 2px 2px; color: #64748B; font-weight: 500; text-align: left; vertical-align: top; white-space: nowrap; }
.tsocIs__kv td { padding: 2px 0; color: #E2E8F0; overflow-wrap: anywhere; }
.tsocIs__log, .tsocIs__json pre { margin: 8px 0 0; padding: 9px 10px; border-radius: 8px; background: #05070A; border: 1px solid rgba(255, 255, 255, .07); color: #A7F3D0; font: 400 11px/1.55 ui-monospace, "SF Mono", Consolas, monospace; white-space: pre-wrap; overflow-wrap: anywhere; }
.tsocIs__json { margin-top: 8px; }
.tsocIs__json summary { color: #94A3B8; font-size: 12px; cursor: pointer; }
.tsocIs__json pre { color: #CBD5E1; max-height: 260px; overflow: auto; }
.tsocIs .tsocLv--compact { margin-top: 8px; }
.tsocIs__tabs .tsocIs__tools { display: inline-flex; gap: 2px; margin-left: auto; }
.tsocIs__tabs .tsocIs__tools + a { margin-left: 8px; }
.tsocIs__tabs .tsocIs__tools button { padding: 3px 8px; border: 1px solid rgba(255, 255, 255, .1); color: #CBD5E1; font-weight: 500; font-size: 11.5px; }
.tsocIs__tabs .tsocIs__tools button:hover { background: rgba(255, 255, 255, .08); color: #fff; }
/* Pestaña "En vivo": el registro real del servicio, línea a línea. */
.tsocIs__liveHead { display: flex; align-items: center; gap: 8px; margin: 8px 2px 6px; color: #CBD5E1; font: 500 12px/1.4 var(--tsoc-font); font-variant-numeric: tabular-nums; }
.tsocIs__liveHead i { flex: none; width: 7px; height: 7px; border-radius: 50%; background: #F87171; box-shadow: 0 0 8px #F87171; animation: tsocAsBlinkAnt 1.4s infinite; }
.tsocIs__feed { max-height: 330px; overflow: auto; padding: 8px 10px; border-radius: 8px; background: #05070A; border: 1px solid rgba(255, 255, 255, .07); font: 400 11.5px/1.6 ui-monospace, "SF Mono", Consolas, monospace; }
.tsocIs__ev { display: grid; grid-template-columns: 58px 62px minmax(0, 1fr); column-gap: 8px; color: #CBD5E1; }
.tsocIs__ev time { color: #64748B; }
.tsocIs__ev em { color: #94A3B8; font-style: normal; }
.tsocIs__ev span { overflow-wrap: anywhere; }
.tsocIs__ev b { color: #94A3B8; font-weight: 600; }
.tsocIs__ev--signal em, .tsocIs__ev--signal span { color: #FBBF24; }
.tsocIs__ev--act em, .tsocIs__ev--act span { color: #34D399; }
.tsocIs__ev--warn em, .tsocIs__ev--warn span { color: #F87171; }
.tsocIs__ev--svc em { color: #22D3EE; }
.tsocIs__ev--chat em { color: #A78BFA; }
.tsocIs__ev:first-child { animation: tsocLvIn .3s ease-out both; }
.tsocIs__liveFoot { margin: 6px 2px 0; color: #64748B; font-size: 11px; }
/* Robot de abajo: botón para ocultarlo (aparece al pasar el ratón) y estado oculto. */
.tsocAs__hide { position: absolute; right: -4px; bottom: 56px; width: 20px; height: 20px; padding: 0; border-radius: 50%; border: 1px solid rgba(255, 255, 255, .18); background: #0B0F16; color: #CBD5E1; font: 600 10px/1 var(--tsoc-font); cursor: pointer; opacity: 0; transition: opacity .15s ease; }
.tsocAs:hover .tsocAs__hide, .tsocAs__hide:focus-visible { opacity: 1; }
.tsocAs__hide:hover { background: #1E293B; color: #fff; }
.tsocAs.is-open .tsocAs__hide, .tsocAs.is-hidden .tsocAs__hide, .tsocAs.is-hidden .tsocAs__launcher, .tsocAs.is-hidden .tsocAs__bubble { display: none; }
@keyframes tsocIsPulse { 0% { box-shadow: 0 0 0 0 color-mix(in srgb, var(--lv-c) 60%, transparent); } 100% { box-shadow: 0 0 0 7px transparent; } }
@media (max-width: 1150px) { .tsocIs:not(.is-open) .tsocIs__line, .tsocIs:not(.is-open) .tsocIs__mode { display: none; } }
@media (prefers-reduced-motion: reduce) { .tsocIs * { animation: none !important; } }
.tsocLv__cardHead { margin: 0 22px 2px 0; color: #94A3B8; font: 700 11px/1.2 var(--tsoc-font); letter-spacing: .08em; text-transform: uppercase; }
/* Reproducción: los pasos entran en orden; el total aparece al final. */
.tsocLv.is-replay .tsocLv__step { opacity: 0; animation: tsocLvIn .38s ease-out both; animation-delay: calc(var(--i) * .5s); }
.tsocLv.is-replay .tsocLv__step::before { transform: scaleX(0); animation: tsocLvLine .42s ease-out both; animation-delay: calc(var(--i) * .5s + .12s); }
.tsocLv--compact.is-replay .tsocLv__step::before { transform: scaleY(0); animation-name: tsocLvLineY; }
.tsocLv.is-replay .tsocLv__dot { animation: tsocLvPing .7s ease-out both; animation-delay: calc(var(--i) * .5s); }
.tsocLv.is-replay .tsocLv__total, .tsocLv.is-replay .tsocLv__state { opacity: 0; animation: tsocLvIn .45s ease-out both; animation-delay: calc(var(--n) * .5s); }
@keyframes tsocLvIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: none; } }
@keyframes tsocLvLine { from { transform: scaleX(0); } to { transform: scaleX(1); } }
@keyframes tsocLvLineY { from { transform: scaleY(0); } to { transform: scaleY(1); } }
@keyframes tsocLvPing { 0% { box-shadow: 0 0 0 0 color-mix(in srgb, var(--lv-c) 70%, transparent); } 100% { box-shadow: 0 0 0 10px transparent, 0 0 0 3px #151515; } }
@keyframes tsocLvPulse { 0% { box-shadow: 0 0 0 0 rgba(52, 211, 153, .6); } 100% { box-shadow: 0 0 0 8px transparent; } }
@media (max-width: 900px) { .tsocGd__live .tsocLv:not(.tsocLv--compact) .tsocLv__steps { grid-template-columns: 1fr; row-gap: 10px; } .tsocGd__live .tsocLv:not(.tsocLv--compact) .tsocLv__step::before { display: none; } .tsocLv__row .tsocLv__state { width: auto; } }
@media (prefers-reduced-motion: reduce) { .tsocLv *, .tsocLv__lane i { animation: none !important; opacity: 1 !important; transform: none !important; } }

/* ---- Guardian · centro de mando (12-10): misma información, presentación de consola de operaciones ---- */
.tsocCc { max-width: 1320px; background: radial-gradient(1200px 420px at 50% -120px, color-mix(in srgb, var(--gd) 9%, transparent), transparent 70%), linear-gradient(rgba(255, 255, 255, .018) 1px, transparent 1px) 0 0 / 100% 32px, linear-gradient(90deg, rgba(255, 255, 255, .018) 1px, transparent 1px) 0 0 / 32px 100%; }
.tsocCc h2 { margin: 0; color: #F8FAFC; font: 700 13px/1.2 var(--tsoc-font); letter-spacing: .09em; text-transform: uppercase; }
.tsocCc__bar { display: flex; align-items: center; gap: 18px; flex-wrap: wrap; padding: 2px 2px 16px; }
.tsocCc__title span { display: block; color: #64748B; font: 600 11px/1.3 var(--tsoc-font); letter-spacing: .14em; text-transform: uppercase; }
.tsocCc__title h1 { margin: 2px 0 0; color: #fff; font: 800 30px/1.05 var(--tsoc-font); letter-spacing: -.02em; }
.tsocCc__status { display: inline-flex; align-items: center; gap: 9px; padding: 7px 14px; border-radius: 99px; border: 1px solid color-mix(in srgb, var(--gd) 40%, transparent); background: color-mix(in srgb, var(--gd) 10%, transparent); color: color-mix(in srgb, var(--gd) 70%, #fff); font: 700 12px/1 var(--tsoc-font); letter-spacing: .08em; text-transform: uppercase; }
.tsocCc__status i { width: 8px; height: 8px; border-radius: 50%; background: var(--gd); box-shadow: 0 0 0 0 color-mix(in srgb, var(--gd) 60%, transparent); animation: tsocCcBeat 2s ease-out infinite; }
.tsocCc__status--alert i, .tsocCc__status--defending i { animation-duration: .8s; }
.tsocCc__modeBox { margin-left: auto; text-align: right; }
.tsocCc__modeBox small { display: block; margin-top: 6px; color: #64748B; font-size: 11.5px; }
.tsocCc__seg { display: inline-grid; grid-template-columns: 1fr 1fr; padding: 3px; border-radius: 11px; border: 1px solid rgba(255, 255, 255, .1); background: #0B0D11; }
.tsocCc__seg button { min-width: 112px; height: 32px; padding: 0 14px; border: 0; border-radius: 8px; background: none; color: #94A3B8; font: 700 12.5px/1 var(--tsoc-font); letter-spacing: .03em; cursor: pointer; transition: background .2s ease, color .2s ease; }
.tsocCc__seg button:not(.is-on):hover { color: #fff; background: rgba(255, 255, 255, .06); }
.tsocCc__seg button.is-on { background: #1F2937; color: #fff; cursor: default; box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .1); }
.tsocGd--auto .tsocCc__seg button.is-on { background: linear-gradient(135deg, #059669, #10B981); color: #04130C; box-shadow: 0 0 18px rgba(16, 185, 129, .35); }
.tsocCc__seg button:focus-visible { outline: 2px solid #34D399; outline-offset: 2px; }
.tsocCc__hero { display: grid; grid-template-columns: minmax(250px, 300px) 230px minmax(0, 1fr); gap: 14px; align-items: stretch; }
.tsocCc__core, .tsocCc__gauge, .tsocCc__tile, .tsocCc__node, .tsocCc__panel { border: 1px solid var(--tsoc-border); background: linear-gradient(180deg, rgba(255, 255, 255, .028), rgba(255, 255, 255, 0) 60%), #15171B; }
.tsocCc__core { position: relative; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 6px 16px 16px; border-radius: 16px; overflow: hidden; background: radial-gradient(circle at 50% 38%, color-mix(in srgb, var(--gd) 16%, transparent), transparent 62%), #15171B; }
.tsocCc__core .tsocGd__botWrap { flex: none; height: 176px; display: grid; place-items: center; }
.tsocCc__core .tsocGd__holo { transform: scale(.74); }
.tsocCc__say { max-width: 260px; color: #E2E8F0; font: 500 13.5px/1.45 var(--tsoc-font); text-align: center; }
.tsocCc__gauge { position: relative; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 16px 14px; border-radius: 16px; --g: #34D399; }
.tsocCc__gauge--warn { --g: #FBBF24; } .tsocCc__gauge--bad { --g: #F87171; }
.tsocCc__gauge svg { width: 156px; height: 156px; transform: rotate(-90deg); }
.tsocCc__gaugeTrack { fill: none; stroke: rgba(255, 255, 255, .07); stroke-width: 9; }
.tsocCc__gaugeArc { fill: none; stroke: var(--g); stroke-width: 9; stroke-linecap: round; filter: drop-shadow(0 0 6px var(--g)); transition: stroke-dashoffset 1s cubic-bezier(.2, .8, .2, 1); }
.tsocCc__gaugeInner { fill: none; stroke: rgba(255, 255, 255, .08); stroke-width: 1; stroke-dasharray: 2 5; }
.tsocCc__gaugeNum { position: absolute; top: 16px; left: 0; right: 0; height: 156px; display: flex; flex-direction: column; align-items: center; justify-content: center; }
.tsocCc__gaugeNum b { color: #fff; font: 800 40px/1 var(--tsoc-font); letter-spacing: -.03em; font-variant-numeric: tabular-nums; }
.tsocCc__gaugeNum small { margin-left: 2px; color: #94A3B8; font-size: 16px; font-weight: 600; }
.tsocCc__gaugeNum span { margin-top: 5px; color: var(--g); font: 700 10.5px/1 var(--tsoc-font); letter-spacing: .16em; text-transform: uppercase; }
.tsocCc__gauge p { margin: 10px 0 0; color: #94A3B8; font-size: 12px; line-height: 1.4; text-align: center; }
.tsocCc__gauge p b { color: #E2E8F0; }
.tsocCc__tiles { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
.tsocCc__tile { position: relative; padding: 14px 16px 13px; border-radius: 14px; overflow: hidden; --t: #34D399; }
.tsocCc__tile::before { content: ""; position: absolute; left: 0; top: 14px; bottom: 14px; width: 3px; border-radius: 0 3px 3px 0; background: var(--t); box-shadow: 0 0 12px var(--t); }
.tsocCc__tile--cyan { --t: #22D3EE; } .tsocCc__tile--violet { --t: #A78BFA; } .tsocCc__tile--blue { --t: #60A5FA; } .tsocCc__tile--amber { --t: #FBBF24; } .tsocCc__tile--red { --t: #F87171; }
.tsocCc__tileLabel { color: #94A3B8; font: 600 10.5px/1.3 var(--tsoc-font); letter-spacing: .1em; text-transform: uppercase; }
.tsocCc__tileValue { margin-top: 8px; color: #fff; font: 700 30px/1 ui-monospace, "SF Mono", Consolas, monospace; letter-spacing: -.03em; font-variant-numeric: tabular-nums; }
.tsocCc__tileSub { margin-top: 6px; color: #64748B; font-size: 11.5px; }
/* Flujo del sistema: de los equipos a la verificación, con el estado real de cada tramo. */
.tsocCc__pipe { display: flex; align-items: stretch; margin: 14px 0; }
.tsocCc__node { position: relative; flex: 1 1 0; min-width: 0; padding: 12px 12px 11px 14px; border-radius: 12px; --n: #34D399; }
.tsocCc__node--warn { --n: #FBBF24; } .tsocCc__node--off { --n: #64748B; }
.tsocCc__nodeIdx { position: absolute; right: 10px; top: 9px; color: #334155; font: 700 10px/1 ui-monospace, "SF Mono", Consolas, monospace; }
.tsocCc__node i { display: inline-block; width: 7px; height: 7px; margin-right: 7px; border-radius: 50%; background: var(--n); box-shadow: 0 0 8px var(--n); vertical-align: 1px; }
.tsocCc__node b { color: #94A3B8; font: 600 10.5px/1.3 var(--tsoc-font); letter-spacing: .1em; text-transform: uppercase; }
.tsocCc__node strong { display: block; margin-top: 7px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #F8FAFC; font: 700 15px/1.2 ui-monospace, "SF Mono", Consolas, monospace; font-variant-numeric: tabular-nums; }
.tsocCc__node small { display: block; margin-top: 3px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #64748B; font-size: 11px; }
.tsocCc__wire { flex: 0 0 22px; align-self: center; height: 2px; background: repeating-linear-gradient(90deg, rgba(148, 163, 184, .35) 0 4px, transparent 4px 8px); }
.tsocCc__wire.is-live { background: repeating-linear-gradient(90deg, rgba(52, 211, 153, .8) 0 4px, transparent 4px 8px); background-size: 8px 2px; animation: tsocCcFlow .5s linear infinite; }
.tsocCc__cols { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 14px; align-items: start; }
.tsocCc__panel { padding: 16px 18px; border-radius: 14px; overflow: hidden; }
.tsocCc__panelHead { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 12px; }
.tsocCc__panelHead span { color: #64748B; font: 500 11.5px/1.3 ui-monospace, "SF Mono", Consolas, monospace; text-align: right; }
.tsocCc__log { height: 380px; max-height: none; }
.tsocCc__logEmpty { color: #64748B; }
.tsocCc__foot { margin: 8px 2px 0; color: #475569; font-size: 11px; }
.tsocCc__link { padding: 0; border: 0; background: none; color: #94A3B8; font: 600 12px/1.2 var(--tsoc-font); text-decoration: none; cursor: pointer; }
.tsocCc__link:hover { color: #fff; text-decoration: underline; }
.tsocCc__stories { margin: 0; padding: 0; list-style: none; max-height: 404px; overflow: auto; }
.tsocCc__story { position: relative; display: grid; grid-template-columns: 14px minmax(0, 1fr); column-gap: 12px; padding: 0 2px 16px 0; --s: #94A3B8; }
.tsocCc__story--ok { --s: #34D399; } .tsocCc__story--warn { --s: #FBBF24; } .tsocCc__story--bad { --s: #F87171; }
.tsocCc__story::before { content: ""; position: absolute; left: 6px; top: 16px; bottom: 0; width: 2px; background: rgba(255, 255, 255, .07); }
.tsocCc__story:last-child::before { display: none; }
.tsocCc__storyDot { width: 14px; height: 14px; margin-top: 2px; border-radius: 50%; background: #15171B; border: 2px solid var(--s); box-shadow: 0 0 10px color-mix(in srgb, var(--s) 50%, transparent); }
.tsocCc__storyHead { display: flex; align-items: baseline; gap: 10px; min-width: 0; }
.tsocCc__storyHead b { color: var(--s); font: 700 12px/1.3 var(--tsoc-font); letter-spacing: .06em; text-transform: uppercase; white-space: nowrap; }
.tsocCc__storyHead span { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #CBD5E1; font-size: 12.5px; }
.tsocCc__storyHead time { flex: none; color: #64748B; font-size: 11.5px; }
.tsocCc__story p { margin: 5px 0 8px; color: #E2E8F0; font-size: 13.5px; line-height: 1.5; }
.tsocCc__storyMeta { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; }
.tsocCc__chip { padding: 2px 8px; border-radius: 6px; border: 1px solid rgba(255, 255, 255, .1); background: rgba(255, 255, 255, .04); color: #CBD5E1; font: 500 11px/1.5 var(--tsoc-font); }
.tsocCc__chip--mono { font-family: ui-monospace, "SF Mono", Consolas, monospace; }
.tsocCc__chip--auto { border-color: rgba(167, 139, 250, .4); background: rgba(167, 139, 250, .12); color: #DDD6FE; }
.tsocCc__storyBtns { display: inline-flex; align-items: center; gap: 12px; margin-left: auto; }
.tsocCc__undo { height: 26px; padding: 0 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, .16); background: rgba(255, 255, 255, .06); color: #F1F5F9; font: 600 12px/1 var(--tsoc-font); cursor: pointer; }
.tsocCc__undo:hover { background: rgba(255, 255, 255, .12); }
.tsocCc .tsocGd__live { margin-bottom: 14px; border-radius: 14px; background: linear-gradient(180deg, rgba(255, 255, 255, .028), rgba(255, 255, 255, 0) 60%), #15171B; }
.tsocCc .tsocGd__live .tsocGd__feedHead h2 { font: 700 13px/1.2 var(--tsoc-font); }
@keyframes tsocCcBeat { 0% { box-shadow: 0 0 0 0 color-mix(in srgb, var(--gd) 60%, transparent); } 100% { box-shadow: 0 0 0 9px transparent; } }
@keyframes tsocCcFlow { from { background-position: 0 0; } to { background-position: 8px 0; } }
@media (max-width: 1250px) { .tsocCc__hero { grid-template-columns: minmax(0, 1fr) 230px; } .tsocCc__tiles { grid-column: 1 / -1; } .tsocCc__pipe { flex-wrap: wrap; gap: 10px; } .tsocCc__wire { display: none; } .tsocCc__node { flex: 1 1 30%; } }
@media (max-width: 900px) { .tsocCc__hero, .tsocCc__cols { grid-template-columns: minmax(0, 1fr); } .tsocCc__tiles { grid-template-columns: repeat(2, minmax(0, 1fr)); } .tsocCc__modeBox { margin-left: 0; text-align: left; } .tsocCc__node { flex: 1 1 45%; }
  .tsocGd__live .tsocLv:not(.tsocLv--compact) .tsocLv__step { grid-template-rows: none; grid-template-columns: 70px 14px minmax(0, 1fr); column-gap: 8px; row-gap: 0; align-items: start; } }
@media (prefers-reduced-motion: reduce) { .tsocCc *, .tsocCc__wire.is-live { animation: none !important; } }
.tsocIs__feed .tsocIs__sub { margin: 0; color: #64748B; font: 400 11.5px/1.6 ui-monospace, "SF Mono", Consolas, monospace; letter-spacing: 0; text-transform: none; }
/* La isla cuelga de la cabecera: sin borde superior y con las esquinas de arriba rectas. */
.tsocIs { top: 48px; border-top: 0; border-radius: 0 0 16px 16px; }
.tsocIs__pill:focus-visible { border-radius: 0 0 16px 16px; }
.tsocCc__bar { padding-top: 22px; }
.tsocIs__ev--cmd em { color: #7DD3FC; }
.tsocIs__ev--cmd span { color: #E0F2FE; }
.tsocIs__ev { grid-template-columns: 58px 66px minmax(0, 1fr); }

/* ==== 13-10: menú con propósito de cada pantalla, isla que cambia de color y pipeline con casillas ==== */
/* ---- Menú: icono en su ficha de color + para qué sirve la pantalla, agrupado por tarea ---- */
.tsocNav__group { padding: 12px 10px 5px; font: 700 10.5px/1 var(--tsoc-font); letter-spacing: .12em; text-transform: uppercase; color: #737373; }
.tsocNav__selector + .tsocNav__group { padding-top: 2px; }
.tsocNav__item--rich { align-items: center; gap: 10px; min-height: 46px; padding: 6px 8px; }
.tsocNav__ico { flex: 0 0 30px; display: grid; place-items: center; width: 30px; height: 30px; border-radius: 9px; --ni: #94A3B8; background: color-mix(in srgb, var(--ni) 14%, transparent); border: 1px solid color-mix(in srgb, var(--ni) 26%, transparent); }
.tsocNav__ico svg, .tsocNav__item--active .tsocNav__ico svg { flex: none; width: 16px; height: 16px; color: var(--ni); }
.tsocNav__ico--green { --ni: #34D399; } .tsocNav__ico--blue { --ni: #60A5FA; } .tsocNav__ico--red { --ni: #F87171; } .tsocNav__ico--amber { --ni: #FBBF24; }
.tsocNav__ico--cyan { --ni: #22D3EE; } .tsocNav__ico--violet { --ni: #A78BFA; } .tsocNav__ico--slate { --ni: #94A3B8; }
.tsocNav__item--rich .tsocNav__label { display: block; white-space: normal; overflow: visible; min-width: 0; }
.tsocNav__item--rich .tsocNav__label b { display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-weight: 600; font-size: 13.5px; line-height: 1.25; color: #E5E5E5; }
.tsocNav__item--rich .tsocNav__label small { display: block; margin-top: 1px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font: 400 11px/1.3 var(--tsoc-font); color: #8A8A8A; }
.tsocNav__item--active.tsocNav__item--rich .tsocNav__label b { color: #fff; }
.tsocNav__item--active.tsocNav__item--rich .tsocNav__label small { color: #C4C4C4; }
.tsocNav__item--active .tsocNav__ico { background: color-mix(in srgb, var(--ni) 26%, transparent); box-shadow: 0 0 12px color-mix(in srgb, var(--ni) 30%, transparent); }

/* ---- Isla: dónde estoy + color según la situación ---- */
.tsocIs { max-width: min(640px, calc(100vw - 24px)); transition: border-radius .2s ease, box-shadow .25s ease, background-color .6s ease, border-color .6s ease; }
.tsocIs.is-open { width: min(560px, calc(100vw - 24px)); }
.tsocIs__where { flex: none; display: inline-flex; align-items: center; gap: 6px; margin-right: 2px; padding-right: 10px; border-right: 1px solid rgba(255, 255, 255, .16); color: #E2E8F0; font: 600 12px/1 var(--tsoc-font); }
.tsocIs__where svg { width: 14px; height: 14px; opacity: .9; }
.tsocIs__ico { flex: none; width: 17px; height: 17px; fill: none; stroke: currentColor; stroke-width: 2.2; stroke-linecap: round; stroke-linejoin: round; }
.tsocIs__here { display: flex; align-items: center; gap: 8px; margin: 9px 0 0; padding: 7px 10px; border-radius: 9px; background: rgba(255, 255, 255, .05); color: #CBD5E1; font-size: 12.5px; }
.tsocIs__here svg { flex: none; width: 16px; height: 16px; color: #94A3B8; }
.tsocIs__here b { color: #fff; }
/* Rojo: hay una amenaza y todavía no está resuelta. */
.tsocIs--danger { --lv-c: #F87171; background: linear-gradient(180deg, #B91C1C, #991B1B); border-color: #FCA5A5; color: #fff; box-shadow: 0 6px 26px rgba(220, 38, 38, .55), 0 0 0 1px rgba(252, 165, 165, .5); animation: tsocIsAlarm 1.1s ease-in-out infinite; }
.tsocIs--danger .tsocIs__line, .tsocIs--danger .tsocIs__where, .tsocIs--danger .tsocIs__mode, .tsocIs--danger .tsocIs__chev { color: #fff; }
.tsocIs--danger .tsocIs__mode, .tsocIs--safe .tsocIs__mode, .tsocIs--undo .tsocIs__mode { border-color: rgba(255, 255, 255, .45); }
.tsocIs--danger .tsocIs__ico { animation: tsocIsBlink 1.1s ease-in-out infinite; }
/* Verde lleno: la amenaza se acaba de resolver con un cambio real. */
.tsocIs--safe { --lv-c: #34D399; background: linear-gradient(180deg, #047857, #065F46); border-color: #6EE7B7; color: #fff; box-shadow: 0 6px 26px rgba(16, 185, 129, .45), 0 0 0 1px rgba(110, 231, 183, .5); }
.tsocIs--safe .tsocIs__line, .tsocIs--safe .tsocIs__where, .tsocIs--safe .tsocIs__chev, .tsocIs--safe .tsocIs__mode { color: #fff; }
.tsocIs--safe.is-flip { animation: tsocIsFlip 1.4s ease-out both; }
.tsocIs--safe.is-flip .tsocIs__ico { animation: tsocIsPop .7s cubic-bezier(.2, 1.6, .4, 1) .25s both; }
/* Azul: se deshace (o se deshizo) un cambio a petición de una persona. No es una defensa. */
.tsocIs--undo { --lv-c: #60A5FA; background: linear-gradient(180deg, #1E3A8A, #1E3370); border-color: #93C5FD; color: #fff; box-shadow: 0 6px 22px rgba(37, 99, 235, .4), 0 0 0 1px rgba(147, 197, 253, .45); }
.tsocIs--undo .tsocIs__line, .tsocIs--undo .tsocIs__where, .tsocIs--undo .tsocIs__chev, .tsocIs--undo .tsocIs__mode { color: #fff; }
.tsocIs--danger.is-open, .tsocIs--safe.is-open, .tsocIs--undo.is-open { background: rgba(10, 12, 16, .96); animation: none; }
.tsocIs--danger.is-open .tsocIs__pill { background: linear-gradient(180deg, #B91C1C, #991B1B); }
.tsocIs--safe.is-open .tsocIs__pill { background: linear-gradient(180deg, #047857, #065F46); }
.tsocIs--undo.is-open .tsocIs__pill { background: linear-gradient(180deg, #1E3A8A, #1E3370); }
@keyframes tsocIsAlarm { 0%, 100% { box-shadow: 0 6px 26px rgba(220, 38, 38, .55), 0 0 0 1px rgba(252, 165, 165, .5); } 50% { box-shadow: 0 6px 34px rgba(220, 38, 38, .85), 0 0 0 5px rgba(248, 113, 113, .3); } }
@keyframes tsocIsBlink { 0%, 100% { opacity: 1; } 50% { opacity: .45; } }
@keyframes tsocIsFlip { 0% { background: linear-gradient(180deg, #B91C1C, #991B1B); box-shadow: 0 0 0 0 rgba(52, 211, 153, .8); } 35% { box-shadow: 0 0 0 14px rgba(52, 211, 153, 0); } 100% { box-shadow: 0 6px 26px rgba(16, 185, 129, .45), 0 0 0 1px rgba(110, 231, 183, .5); } }
@keyframes tsocIsPop { from { transform: scale(0); } to { transform: scale(1); } }
@media (max-width: 1150px) { .tsocIs:not(.is-open) .tsocIs__where { display: none; } .tsocIs--danger:not(.is-open) .tsocIs__line, .tsocIs--safe:not(.is-open) .tsocIs__line, .tsocIs--undo:not(.is-open) .tsocIs__line { display: block; max-width: 46vw; } }

/* ---- Pipeline con casillas: todas las etapas a la vista; cada una se marca al cumplirse ---- */
.tsocLv--undo { --lv-c: #60A5FA; }
.tsocLv__count { flex: none; padding: 2px 8px; border-radius: 99px; border: 1px solid color-mix(in srgb, var(--lv-c) 35%, transparent); color: color-mix(in srgb, var(--lv-c) 75%, #fff); font: 600 11px/1.5 var(--tsoc-font); font-variant-numeric: tabular-nums; white-space: nowrap; }
.tsocLv--pl .tsocLv__step { --st: #475569; grid-template-rows: 18px 24px auto; }
.tsocLv--pl .tsocLv__step.is-done { --st: #34D399; } .tsocLv--pl .tsocLv__step.is-fail { --st: #F87171; }
.tsocLv--pl .tsocLv__step.is-hold { --st: #FBBF24; } .tsocLv--pl .tsocLv__step.is-run { --st: #38BDF8; }
.tsocLv--pl .tsocLv__step::before { top: 35px; left: 24px; background: repeating-linear-gradient(90deg, rgba(148, 163, 184, .4) 0 4px, transparent 4px 8px); }
.tsocLv--pl .tsocLv__step.is-done::before { background: #34D399; }
.tsocLv--pl .tsocLv__step:last-child::before { display: none; }
.tsocLv--pl .tsocLv__t { color: var(--st); }
.tsocLv--pl .tsocLv__dot { display: grid; place-items: center; width: 24px; height: 24px; border: 2px solid var(--st); background: #151515; box-shadow: 0 0 0 3px #151515; }
.tsocLv--pl .tsocLv__dot svg { width: 14px; height: 14px; fill: none; stroke: #04130C; stroke-width: 2.6; stroke-linecap: round; stroke-linejoin: round; }
.tsocLv--pl .is-done .tsocLv__dot, .tsocLv--pl .is-fail .tsocLv__dot, .tsocLv--pl .is-hold .tsocLv__dot { background: var(--st); box-shadow: 0 0 0 3px #151515, 0 0 12px color-mix(in srgb, var(--st) 55%, transparent); }
.tsocLv--pl .is-fail .tsocLv__dot svg { stroke: #fff; }
.tsocLv--pl .is-skip .tsocLv__dot { border-style: dashed; } .tsocLv--pl .is-skip .tsocLv__dot svg { stroke: #64748B; }
.tsocLv--pl .is-run .tsocLv__dot { border-color: rgba(56, 189, 248, .25); border-top-color: #38BDF8; animation: tsocPlSpin .8s linear infinite; }
.tsocLv--pl .is-todo .tsocLv__txt, .tsocLv--pl .is-skip .tsocLv__txt { opacity: .5; }
.tsocLv--pl .is-run .tsocLv__txt b { color: #BAE6FD; } .tsocLv--pl .is-hold .tsocLv__txt b { color: #FDE68A; } .tsocLv--pl .is-fail .tsocLv__txt b { color: #FECACA; }
.tsocLv--pl.tsocLv--compact .tsocLv__step { grid-template-rows: none; grid-template-columns: 62px 24px minmax(0, 1fr); }
.tsocLv--pl.tsocLv--compact .tsocLv__step::before { top: 26px; bottom: 0; left: 81px; width: 2px; height: auto; background: repeating-linear-gradient(180deg, rgba(148, 163, 184, .4) 0 4px, transparent 4px 8px); }
.tsocLv--pl.tsocLv--compact .tsocLv__step.is-done::before { background: #34D399; }
.tsocLv--pl.tsocLv--compact .tsocLv__dot { margin-top: 0; }
.tsocLv--pl.tsocLv--compact .tsocLv__txt { padding-top: 3px; }
.tsocLv--compact .tsocLv__count { order: 2; }
/* Reproducción: las etapas están a la vista desde el principio y las casillas se van marcando una a una. */
.tsocLv--pl.is-replay .tsocLv__step { opacity: 1; animation: none; }
.tsocLv--pl.is-replay .tsocLv__step.is-done .tsocLv__dot, .tsocLv--pl.is-replay .tsocLv__step.is-fail .tsocLv__dot, .tsocLv--pl.is-replay .tsocLv__step.is-hold .tsocLv__dot { animation: tsocPlTick .45s cubic-bezier(.2, 1.5, .4, 1) both; animation-delay: calc(var(--i) * .55s + .2s); }
.tsocLv--pl.is-replay .tsocLv__step .tsocLv__dot svg { animation: tsocPlMark .3s ease-out both; animation-delay: calc(var(--i) * .55s + .32s); }
.tsocLv--pl.is-replay .tsocLv__step .tsocLv__txt, .tsocLv--pl.is-replay .tsocLv__step .tsocLv__t { animation: tsocPlText .35s ease-out both; animation-delay: calc(var(--i) * .55s + .2s); }
.tsocLv--pl.is-replay .tsocLv__step::before { animation: tsocLvLine .4s ease-out both; animation-delay: calc(var(--i) * .55s + .45s); }
.tsocLv--pl.tsocLv--compact.is-replay .tsocLv__step::before { animation-name: tsocLvLineY; }
.tsocLv--pl.is-replay .tsocLv__total, .tsocLv--pl.is-replay .tsocLv__state { animation-delay: calc(var(--n) * .55s); }
.tsocLv--pl.is-replay .tsocLv__count { opacity: 0; animation: tsocLvIn .45s ease-out both; animation-delay: calc(var(--n) * .55s); }
@keyframes tsocPlSpin { to { transform: rotate(360deg); } }
@keyframes tsocPlTick { 0% { background: #151515; border-color: #475569; box-shadow: 0 0 0 3px #151515; transform: scale(.7); } 100% { transform: scale(1); } }
@keyframes tsocPlMark { from { opacity: 0; transform: scale(.2); } to { opacity: 1; transform: scale(1); } }
@keyframes tsocPlText { from { opacity: .3; } }
@media (max-width: 900px) { .tsocGd__live .tsocLv--pl:not(.tsocLv--compact) .tsocLv__step { grid-template-rows: none; grid-template-columns: 70px 24px minmax(0, 1fr); } }
@media (prefers-reduced-motion: reduce) { .tsocIs, .tsocIs * { animation: none !important; } }

/* ---- Guardian: deshacer tiene su propio estado y color (no es "defendiendo") ---- */
.tsocGd--undoing { --gd: #60A5FA; --gd-soft: rgba(96, 165, 250, .16); }
.tsocAs[data-state="undoing"] { --as-c: #93C5FD; --as-c2: #3B82F6; }
.tsocCc__status--undoing i { animation-duration: 1.2s; }
.tsocCc__story--undo { --s: #60A5FA; }

/* ---- 13-10 (tarde): robot en verde cuando la amenaza queda contenida ---- */
.tsocAs[data-state="safe"] { --as-c: #34D399; --as-c2: #10B981; }
.tsocAs[data-state="safe"] .tsocAs__ring { animation-duration: 2.4s; }
.tsocGd--safe { --gd: #10B981; --gd-soft: rgba(16, 185, 129, .18); }
.tsocCc__status--safe { color: #34D399; }
.tsocCc__status--safe i { background: #10B981; box-shadow: 0 0 10px #10B981; }
