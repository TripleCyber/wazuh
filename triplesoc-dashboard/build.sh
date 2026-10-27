#!/usr/bin/env bash
# Construye la imagen del dashboard con la capa TripleSOC.
#   ./build.sh [WAZUH_VERSION]        p. ej. ./build.sh 4.14.8
# Variables opcionales: IMAGE (default triplesoc/wazuh-dashboard), TAG (default la versión de Wazuh),
# WAZUH_PLUGINS=1 para conservar los plugins de Wazuh (variante anterior), PUSH=1 para subirla.
set -euo pipefail
cd "$(dirname "$0")"

WAZUH_VERSION=${1:-${WAZUH_VERSION:-4.14.7}}
IMAGE=${IMAGE:-triplesoc/wazuh-dashboard}
TAG=${TAG:-$WAZUH_VERSION}

# Capa traductora: el contrato vive en ../schema y se copia al contexto en cada build.
rm -rf .schema && mkdir .schema && cp ../schema/triplesoc-schema.json .schema/

docker build \
  --build-arg WAZUH_VERSION="$WAZUH_VERSION" \
  --build-arg WAZUH_PLUGINS="${WAZUH_PLUGINS:-0}" \
  -t "$IMAGE:$TAG" \
  .

echo "Imagen lista: $IMAGE:$TAG"
# La imagen se aplana en una capa: la construcción deja varios GB de caché intermedia que no se reutiliza.
# El 27-10 llevó el disco al 89 % (al 90 % el indexer deja de crear índices). KEEP_BUILD_CACHE=1 la conserva.
if [[ "${KEEP_BUILD_CACHE:-0}" != 1 ]]; then docker builder prune -f >/dev/null && echo "Caché de construcción liberada"; fi

if [[ "${PUSH:-0}" == 1 ]]; then docker push "$IMAGE:$TAG"; fi
