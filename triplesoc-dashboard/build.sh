#!/usr/bin/env bash
# Construye la imagen del dashboard con la capa TripleSOC.
#   ./build.sh [WAZUH_VERSION]        p. ej. ./build.sh 4.14.8
# Variables opcionales: IMAGE (default triplesoc/wazuh-dashboard), PUSH=1 para subirla.
set -euo pipefail
cd "$(dirname "$0")"

WAZUH_VERSION=${1:-${WAZUH_VERSION:-4.14.7}}
IMAGE=${IMAGE:-triplesoc/wazuh-dashboard}

# Capa traductora: el contrato vive en ../schema y se copia al contexto en cada build.
rm -rf .schema && mkdir .schema && cp ../schema/triplesoc-schema.json .schema/

docker build \
  --build-arg WAZUH_VERSION="$WAZUH_VERSION" \
  -t "$IMAGE:$WAZUH_VERSION" \
  .

echo "Imagen lista: $IMAGE:$WAZUH_VERSION"
if [[ "${PUSH:-0}" == 1 ]]; then docker push "$IMAGE:$WAZUH_VERSION"; fi
