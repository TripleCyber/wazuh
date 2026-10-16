#!/bin/bash
# SBOM (lista de componentes) + vulnerabilidades conocidas + licencias de cada imagen de TripleSOC.
# Solo lee las imágenes: no toca contenedores ni el compose.
#   ./sbom.sh                → imágenes del compose de Coolify
#   ./sbom.sh img1 img2 ...  → imágenes concretas (por ejemplo, las del canario)
# Resultado en /opt/triplesoc/sbom/AAAAMMDD-HHMM/: <imagen>.cdx.json (CycloneDX), <imagen>.vulns.json
# (Trivy) y RESUMEN.md. Las herramientas se ejecutan en contenedores con versión fija; las
# imágenes se pasan como archivo (docker save) para no darles acceso al socket de Docker.
set -u
SID=${SID:-yf8u7icjiq4vdhetmea7rmfr}
SVC_DIR=${SVC_DIR:-/data/coolify/services/$SID}
SYFT=${SYFT:-anchore/syft:v1.18.1}
TRIVY=${TRIVY:-aquasec/trivy:0.58.1}
BASE=${BASE:-/opt/triplesoc/sbom}
OUT=$BASE/$(date -u +%Y%m%d-%H%M)
CACHE=$BASE/.trivy-cache
TMP=$BASE/.tmp
mkdir -p "$OUT" "$CACHE" "$TMP"

if [ $# -gt 0 ]; then IMAGES=("$@"); else
  mapfile -t IMAGES < <(grep -E '^\s+image:' "$SVC_DIR/docker-compose.yml" | sed -E "s/.*image: *['\"]?([^'\"]+)['\"]?/\1/")
fi

{
  echo "# SBOM TripleSOC · $(date -u '+%F %T') UTC"
  echo
  echo "Herramientas: $SYFT (inventario) · $TRIVY (vulnerabilidades). Cada CVE se cuenta una vez por imagen, tenga parche o no."
  echo
  echo "| Imagen | ID | Componentes | Críticas | Altas | Medias | Bajas |"
  echo "|---|---|---:|---:|---:|---:|---:|"
} > "$OUT/RESUMEN.md"
LIC=$OUT/.licencias.tsv; : > "$LIC"

for img in "${IMAGES[@]}"; do
  name=$(echo "$img" | tr '/:' '__')
  id=$(docker image inspect -f '{{.Id}}' "$img" 2>/dev/null | cut -c8-19)
  if [ -z "$id" ]; then echo "SALTADA $img (no existe)"; echo "| $img | — | no existe | | | | |" >> "$OUT/RESUMEN.md"; continue; fi
  echo "== $img ($id)"
  docker save "$img" -o "$TMP/img.tar" || { echo "  error en docker save"; continue; }
  docker run --rm -v "$TMP:/in:ro" -v "$OUT:/out" "$SYFT" "docker-archive:/in/img.tar" \
    -q -o "cyclonedx-json=/out/$name.cdx.json" || echo "  error en syft"
  rm -f "$TMP/img.tar"
  docker run --rm -v "$OUT:/out" -v "$CACHE:/root/.cache/trivy" "$TRIVY" sbom -q \
    --format json -o "/out/$name.vulns.json" "/out/$name.cdx.json" || echo "  error en trivy"
  comp=$(jq '.components | length' "$OUT/$name.cdx.json" 2>/dev/null)
  sev() { jq --arg s "$1" '[.Results[]?.Vulnerabilities[]? | select(.Severity==$s) | .VulnerabilityID] | unique | length' "$OUT/$name.vulns.json" 2>/dev/null; }
  echo "| \`$img\` | $id | ${comp:-?} | $(sev CRITICAL) | $(sev HIGH) | $(sev MEDIUM) | $(sev LOW) |" >> "$OUT/RESUMEN.md"
  jq -r --arg i "$img" '.components[]? | [ $i, ((.licenses // []) | map(.license.id // .license.name // .expression) | join(" OR ") | if .=="" then "(sin declarar)" else . end) ] | @tsv' \
    "$OUT/$name.cdx.json" >> "$LIC" 2>/dev/null
done

{
  echo
  echo "## Licencias más frecuentes (componentes por licencia, todas las imágenes)"
  echo
  echo "| Licencia | Componentes |"
  echo "|---|---:|"
  cut -f2 "$LIC" | sort | uniq -c | sort -rn | head -25 | awk '{n=$1; $1=""; sub(/^ /,""); printf "| %s | %d |\n", $0, n}'
  echo
  echo "## Licencias de copia fuerte (GPL/AGPL/LGPL) por imagen"
  echo
  echo "| Imagen | Componentes GPL/AGPL/LGPL |"
  echo "|---|---:|"
  grep -E 'GPL' "$LIC" | cut -f1 | sort | uniq -c | awk '{printf "| `%s` | %d |\n", $2, $1}'
  echo
  echo "## Vulnerabilidades críticas (máximo 40)"
  echo
  echo "| Imagen | CVE | Paquete | Versión | Corregida en |"
  echo "|---|---|---|---|---|"
  for f in "$OUT"/*.vulns.json; do
    i=$(basename "$f" .vulns.json)
    jq -r --arg i "$i" '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | unique_by(.VulnerabilityID+.PkgName)[] | "| \($i) | \(.VulnerabilityID) | \(.PkgName) | \(.InstalledVersion) | \(.FixedVersion // "sin parche") |"' "$f" 2>/dev/null
  done | head -40
} >> "$OUT/RESUMEN.md"
rm -f "$LIC"; rmdir "$TMP" 2>/dev/null
ln -sfn "$OUT" "$BASE/ultimo"
echo "Listo: $OUT/RESUMEN.md"
