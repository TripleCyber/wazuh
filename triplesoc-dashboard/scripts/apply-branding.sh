#!/usr/bin/env bash
# Inyecta la capa visual TripleSOC sobre una instalación base de wazuh-dashboard.
#   apply-branding.sh <SRC: árbol original> <OUT: solo los archivos modificados>
# Se ejecuta en la etapa "patcher" del Dockerfile. Falla el build si un punto de
# marca obligatorio no existe en la versión base (así una actualización de Wazuh
# que mueva archivos se detecta al construir, no en producción).
set -euo pipefail

SRC=${1:?SRC}
OUT=${2:?OUT}
BRAND=${BRAND_DIR:-/brand}
OVERLAY=${OVERLAY_DIR:-/overlay}
SCHEMA_JSON=${SCHEMA_JSON:-/schema/triplesoc-schema.json}
WORK=$(mktemp -d)

set -a; . "$BRAND/brand.env"; set +a
VARS='${TSOC_APP_TITLE} ${TSOC_DARK} ${TSOC_GREEN} ${TSOC_RED} ${TSOC_RED_ON_DARK} ${TSOC_GRAY} ${TSOC_PRIMARY} ${TSOC_PRIMARY_HOVER} ${TSOC_PRIMARY_RGB} ${TSOC_ACCENT} ${TSOC_ACCENT_RGB} ${TSOC_ACCENT_DARK} ${TSOC_ACCENT_DARK_RGB} ${SPINNER_SHIELD}'

log()  { echo "[triplesoc] $*"; }
fail() { echo "[triplesoc] ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------- 1. assets
log "Renderizando assets de marca"
render() { SPINNER_SHIELD=${2:-$TSOC_DARK} envsubst "$VARS" < "$BRAND/$1.svg.tpl" > "$WORK/$1${3:-}.svg"; }
render mark; render mark-on-dark; render mark-mono; render logo; render logo-on-dark; render login-bg
render spinner "$TSOC_DARK"; render spinner "#262626" -on-dark

png() { rsvg-convert "$@"; }
mkdir -p "$WORK/fav"
for s in 16 32 48 70 144 150 180 192 310 512; do png -w $s -h $s "$WORK/mark.svg" -o "$WORK/fav/$s.png"; done
png -w 310 -h 150 -a "$WORK/mark.svg" -o "$WORK/fav/310x150.png" 2>/dev/null || cp "$WORK/fav/150.png" "$WORK/fav/310x150.png"
if command -v magick >/dev/null; then IM=magick; else IM=convert; fi
$IM "$WORK/fav/16.png" "$WORK/fav/32.png" "$WORK/fav/48.png" "$WORK/fav/favicon.ico"
png -h 120 "$WORK/logo.svg" -o "$WORK/logo_reports.png"

# ---------------------------------------------------------------- 2. reemplazos
declare -A ORIG_MD5   # md5 original -> archivo de reemplazo (para detectar copias con hash)
COUNT=0
put() { # put <reemplazo> <ruta relativa> [required|optional]
  local rep=$1 rel=$2 mode=${3:-optional}
  if [[ ! -f "$SRC/$rel" ]]; then
    [[ $mode == required ]] && fail "punto de marca obligatorio no encontrado: $rel"
    log "  (omitido, no existe en esta versión) $rel"; return 0
  fi
  ORIG_MD5[$(md5sum < "$SRC/$rel" | cut -c1-32)]=$rep
  install -D -m 0644 "$rep" "$OUT/$rel"
  COUNT=$((COUNT+1))
}

A=src/core/server/core_app/assets
log "Reemplazando logos del núcleo"
# El encabezado es oscuro en la capa TripleSOC: su marca usa la variante on-dark.
put "$WORK/mark-on-dark.svg"    $A/logos/wazuh_mark_on_light.svg required
put "$WORK/spinner.svg"         $A/logos/spinner_on_light.svg required
put "$WORK/spinner-on-dark.svg" $A/logos/spinner_on_dark.svg
for f in wazuh_mark wazuh_center_mark wazuh_center_mark_on_light icon_light; do put "$WORK/mark.svg" $A/logos/$f.svg; done
for f in wazuh_mark_on_dark wazuh_center_mark_on_dark icon_dark; do put "$WORK/mark-on-dark.svg" $A/logos/$f.svg; done
for f in wazuh wazuh_on_light wazuh_dashboards wazuh_dashboards_on_light; do put "$WORK/logo.svg" $A/logos/$f.svg; done
for f in wazuh_on_dark wazuh_dashboards_on_dark; do put "$WORK/logo-on-dark.svg" $A/logos/$f.svg; done
put "$WORK/mark.svg"         $A/default_branding/opensearch_mark_default_mode.svg
put "$WORK/mark-on-dark.svg" $A/default_branding/opensearch_mark_dark_mode.svg
put "$WORK/logo.svg"         $A/wazuh_logo.svg
put "$WORK/login-bg.svg"     $A/wazuh_login_bg.svg

log "Reemplazando favicons"
F=$A/favicons
put "$WORK/fav/favicon.ico" $F/favicon.ico required
put "$WORK/fav/16.png"  $F/favicon-16x16.png
put "$WORK/fav/32.png"  $F/favicon-32x32.png
put "$WORK/fav/180.png" $F/apple-touch-icon.png
put "$WORK/fav/192.png" $F/android-chrome-192x192.png
put "$WORK/fav/512.png" $F/android-chrome-512x512.png
put "$WORK/fav/70.png"  $F/mstile-70x70.png
put "$WORK/fav/144.png" $F/mstile-144x144.png
put "$WORK/fav/150.png" $F/mstile-150x150.png
put "$WORK/fav/310.png" $F/mstile-310x310.png
put "$WORK/fav/310x150.png" $F/mstile-310x150.png
put "$WORK/mark-mono.svg" $F/safari-pinned-tab.svg
if [[ -f "$SRC/$F/manifest.json" ]]; then
  install -D -m 0644 "$SRC/$F/manifest.json" "$OUT/$F/manifest.json"
  sed -i -E "s/\"(short_)?name\": *\"[^\"]*\"/\"\1name\": \"$TSOC_APP_TITLE\"/g" "$OUT/$F/manifest.json"
fi

log "Reemplazando logos de login y plugins"
# La capa es oscura: el login usa el logo con texto claro.
put "$WORK/logo-on-dark.svg" plugins/securityDashboards/public/assets/ui/wazuh_logo.svg required
W=plugins/wazuh/public/assets/images
put "$WORK/logo.svg"         $W/themes/light/logo.svg
put "$WORK/logo-on-dark.svg" $W/themes/dark/logo.svg
put "$WORK/mark.svg"         $W/themes/light/icon.svg
put "$WORK/mark-on-dark.svg" $W/themes/dark/icon.svg
put "$WORK/logo_reports.png" $W/logo_reports.png

# Copias compiladas con nombre hash (p. ej. target/public/30e500….svg): se detectan
# por contenido idéntico al original, así no dependemos de hashes que cambian entre versiones.
log "Buscando copias con hash de los logos originales"
while IFS= read -r -d '' f; do
  m=$(md5sum < "$f" | cut -c1-32)
  if [[ -n "${ORIG_MD5[$m]:-}" ]]; then
    rel=${f#"$SRC/"}
    [[ -f "$OUT/$rel" ]] && continue
    install -D -m 0644 "${ORIG_MD5[$m]}" "$OUT/$rel"; COUNT=$((COUNT+1)); log "  copia: $rel"
  fi
done < <(find "$SRC/plugins" "$SRC/src/core" -path '*/target/public/*' -type f \( -name '*.svg' -o -name '*.png' \) -size -200k -print0)
log "Archivos de imagen reemplazados: $COUNT"

# ---------------------------------------------------------------- 3. título
log "Título de la aplicación -> $TSOC_APP_TITLE"
CFG=src/core/server/opensearch_dashboards_config.js
[[ -f "$SRC/$CFG" ]] || fail "no existe $CFG"
install -D -m 0644 "$SRC/$CFG" "$OUT/$CFG"
TSOC_APP_TITLE="$TSOC_APP_TITLE" perl -0pi -e \
  's/(applicationTitle:\s*_configSchema\.schema\.string\(\{\s*defaultValue:\s*)\x27[^\x27]*\x27/$1\x27$ENV{TSOC_APP_TITLE}\x27/' "$OUT/$CFG"
grep -q "defaultValue: '$TSOC_APP_TITLE'" "$OUT/$CFG" || fail "no se pudo parchear applicationTitle en $CFG"

# ---------------------------------------------------------------- 4. tema oscuro por defecto
log "Tema oscuro por defecto"
THEME_JS=src/core/server/ui_settings/settings/theme.js
[[ -f "$SRC/$THEME_JS" ]] || fail "no existe $THEME_JS"
install -D -m 0644 "$SRC/$THEME_JS" "$OUT/$THEME_JS"
perl -0pi -e "s/('theme:darkMode':\s*\{.{0,300}?value:\s*)false/\${1}true/s" "$OUT/$THEME_JS"
perl -0ne "exit(/'theme:darkMode':\s*\{.{0,300}?value:\s*true/s ? 0 : 1)" "$OUT/$THEME_JS" \
  || fail "no se pudo activar theme:darkMode en $THEME_JS"

# ---------------------------------------------------------------- 4b. menú lateral anclado
# El menú se muestra anclado salvo que el usuario lo desancle (core.chrome.isLocked="false").
# El bundle se sirve también precomprimido: se regeneran .gz y .br para que coincidan.
log "Menú lateral anclado por defecto"
CORE_JS=src/core/target/public/core.entry.js
[[ -f "$SRC/$CORE_JS" ]] || fail "no existe $CORE_JS"
install -D -m 0644 "$SRC/$CORE_JS" "$OUT/$CORE_JS"
[[ $(grep -o 'getItem(IS_LOCKED_KEY)==="true"' "$OUT/$CORE_JS" | wc -l) -eq 1 ]] \
  || fail "no se encontró (o no es único) el estado por defecto del menú en $CORE_JS"
sed -i 's/getItem(IS_LOCKED_KEY)==="true"/getItem(IS_LOCKED_KEY)!=="false"/' "$OUT/$CORE_JS"
grep -q 'getItem(IS_LOCKED_KEY)!=="false"' "$OUT/$CORE_JS" || fail "no se pudo anclar el menú por defecto"

# ---------------------------------------------------------------- 4b'. capa traductora (esquema)
# Va ANTES que las demás pantallas: define window.TSOC_SCHEMA (índice de alertas, campos y bandas de
# severidad) a partir del contrato schema/triplesoc-schema.json, el mismo que usan los servicios Python.
log "Capa traductora (contrato $(grep -o '"contract": *"[^"]*"' "$SCHEMA_JSON" | cut -d'"' -f4), adaptador $(grep -o '"adapter": *"[^"]*"' "$SCHEMA_JSON" | cut -d'"' -f4))"
SCH_JS=$OVERLAY/triplesoc-schema.js
[[ -f "$SCH_JS" && -f "$SCHEMA_JSON" ]] || fail "no existe $SCH_JS o $SCHEMA_JSON"
[[ $(grep -c '/\*__TSOC_SCHEMA_JSON__\*/null' "$SCH_JS") -eq 1 ]] || fail "marcador del esquema no encontrado en $SCH_JS"
printf '\n' >> "$OUT/$CORE_JS"
SCHEMA_JSON="$SCHEMA_JSON" perl -0pe 'BEGIN { local $/; open my $f, "<", $ENV{SCHEMA_JSON} or die; $j = <$f>; $j =~ s/\s+\z//; } s{/\*__TSOC_SCHEMA_JSON__\*/null}{$j}' "$SCH_JS" >> "$OUT/$CORE_JS"
[[ $(grep -c '==== TripleSOC schema ====' "$OUT/$CORE_JS") -eq 1 ]] || fail "capa traductora no añadida a $CORE_JS"
grep -q '"contract": *"triplesoc.schema/' "$OUT/$CORE_JS" || fail "el contrato no quedó incrustado en $CORE_JS"

# ---------------------------------------------------------------- 4c. entradas propias del menú
# Se AÑADE al final del bundle (no modifica código existente). El script solo usa el DOM del menú
# nativo; si una versión futura lo cambia, las entradas no aparecen y el menú nativo sigue igual.
log "Entradas propias del menú (Overview, Attack Map, ..., ZONES, usuario)"
NAV_JS=$OVERLAY/triplesoc-nav.js
[[ -f "$NAV_JS" ]] || fail "no existe $NAV_JS"
printf '\n' >> "$OUT/$CORE_JS"
cat "$NAV_JS" >> "$OUT/$CORE_JS"
[[ $(grep -c '==== TripleSOC nav ====' "$OUT/$CORE_JS") -eq 1 ]] || fail "menú TripleSOC no añadido a $CORE_JS"

# ---------------------------------------------------------------- 4d. pantalla Incidents
# Igual que el menú: se añade al final del bundle. Lee del índice triplesoc-incidents (servicio aparte).
log "Pantalla Incidents"
INC_JS=$OVERLAY/triplesoc-incidents-ui.js
[[ -f "$INC_JS" ]] || fail "no existe $INC_JS"
printf '\n' >> "$OUT/$CORE_JS"
cat "$INC_JS" >> "$OUT/$CORE_JS"
[[ $(grep -c '==== TripleSOC incidents ====' "$OUT/$CORE_JS") -eq 1 ]] || fail "pantalla Incidents no añadida a $CORE_JS"

# ---------------------------------------------------------------- 4e. pantalla AI Rules
# Igual que Incidents. Lee del índice triplesoc-incidents-rules (servicio triplesoc-rulesmith).
log "Pantalla AI Rules"
RUL_JS=$OVERLAY/triplesoc-rules-ui.js
[[ -f "$RUL_JS" ]] || fail "no existe $RUL_JS"
printf '\n' >> "$OUT/$CORE_JS"
cat "$RUL_JS" >> "$OUT/$CORE_JS"
[[ $(grep -c '==== TripleSOC rules ====' "$OUT/$CORE_JS") -eq 1 ]] || fail "pantalla AI Rules no añadida a $CORE_JS"

# ---------------------------------------------------------------- 4f. pantalla Guardian
# El robot que resume lo que hizo triplesoc-responder y tiene el interruptor Automático / Manual.
log "Pantalla Guardian"
GD_JS=$OVERLAY/triplesoc-guardian-ui.js
[[ -f "$GD_JS" ]] || fail "no existe $GD_JS"
printf '\n' >> "$OUT/$CORE_JS"
cat "$GD_JS" >> "$OUT/$CORE_JS"
[[ $(grep -c '==== TripleSOC guardian ====' "$OUT/$CORE_JS") -eq 1 ]] || fail "pantalla Guardian no añadida a $CORE_JS"

# ---------------------------------------------------------------- 4g. asistente Guardian (todas las pantallas)
# Robot flotante que se presenta en cada sección y conversa (lo contesta triplesoc-responder).
log "Asistente Guardian"
AS_JS=$OVERLAY/triplesoc-assistant.js
[[ -f "$AS_JS" ]] || fail "no existe $AS_JS"
printf '\n' >> "$OUT/$CORE_JS"
cat "$AS_JS" >> "$OUT/$CORE_JS"
[[ $(grep -c '==== TripleSOC assistant ====' "$OUT/$CORE_JS") -eq 1 ]] || fail "asistente Guardian no añadido a $CORE_JS"
gzip -9 -n -c "$OUT/$CORE_JS" > "$OUT/$CORE_JS.gz"
brotli -f -q 11 -o "$OUT/$CORE_JS.br" "$OUT/$CORE_JS"

# ---------------------------------------------------------------- 5. colores
log "Aplicando paleta"
THEME=$A/wz_v7_theme_overwrite.css
[[ -f "$SRC/$THEME" ]] || fail "no existe $THEME (hoja cargada en todas las páginas)"
install -D -m 0644 "$SRC/$THEME" "$OUT/$THEME"
envsubst "$VARS" < "$OVERLAY/triplesoc.css.tpl" >> "$OUT/$THEME"

# Primario de EUI v7 (#006BB4 / #006BB8) y su versión rgba en los CSS compilados.
mapfile -t CSS < <(cd "$SRC" && find src node_modules/@osd -type f \( -name 'osd-ui-shared-deps.v7.light.css' -o -name 'legacy_light_theme.css' -o -name 'kui_light.css' \) 2>/dev/null)
[[ ${#CSS[@]} -gt 0 ]] || fail "no se encontraron los CSS de tema compilados"
for rel in "${CSS[@]}"; do
  install -D -m 0644 "$SRC/$rel" "$OUT/$rel"
  n=$(grep -o -i -E '#006bb[48]|rgba\(0, ?107, ?180' "$OUT/$rel" | wc -l)
  sed -i -E "s/#006[bB][bB][48]/$TSOC_PRIMARY/g; s/rgba\(0, ?107, ?180/rgba($TSOC_PRIMARY_RGB/g" "$OUT/$rel"
  log "  $rel: $n ocurrencias del primario reemplazadas"
done

# Primario de EUI v7 oscuro (#1BA9F5) en los CSS del tema oscuro.
mapfile -t CSS_DARK < <(cd "$SRC" && find src node_modules/@osd -type f \( -name 'osd-ui-shared-deps.v7.dark.css' -o -name 'legacy_dark_theme.css' -o -name 'kui_dark.css' \) 2>/dev/null)
[[ ${#CSS_DARK[@]} -gt 0 ]] || fail "no se encontraron los CSS del tema oscuro"
for rel in "${CSS_DARK[@]}"; do
  install -D -m 0644 "$SRC/$rel" "$OUT/$rel"
  n=$(grep -o -i -E '#1ba9f5|rgba\(27, ?169, ?245' "$OUT/$rel" | wc -l)
  sed -i -E "s/#1[bB][aA]9[fF]5/$TSOC_ACCENT_DARK/g; s/rgba\(27, ?169, ?245/rgba($TSOC_ACCENT_DARK_RGB/g" "$OUT/$rel"
  log "  $rel: $n ocurrencias del primario oscuro reemplazadas"
done

# ---------------------------------------------------------------- 6. reportes PDF
log "Valores por defecto de reportes"
while IFS= read -r rel; do
  install -D -m 0644 "$SRC/$rel" "$OUT/$rel"
  sed -i -e "s/info@wazuh\.com/$TSOC_REPORT_EMAIL/g" -e "s/Wazuh, Inc\./$TSOC_COMPANY/g" "$OUT/$rel"
  log "  $rel"
done < <(cd "$SRC" && grep -rlF 'info@wazuh.com' plugins/wazuh plugins/wazuhCore --include='*.js' 2>/dev/null || true)

# ---------------------------------------------------------------- 7. verificación
grep -q 'TripleSOC visual layer' "$OUT/$THEME" || fail "capa CSS no inyectada"
for rel in $A/logos/wazuh_mark_on_light.svg plugins/securityDashboards/public/assets/ui/wazuh_logo.svg $F/favicon.ico; do
  cmp -s "$SRC/$rel" "$OUT/$rel" && fail "$rel sigue siendo el original"
done
log "OK — $(find "$OUT" -type f | wc -l) archivos en la capa TripleSOC"
