#!/usr/bin/env bash
# Construye wazuh-manager con la tubería TripleSOC.
#   ./build.sh [WAZUH_VERSION]        p. ej. ./build.sh 4.14.8
set -euo pipefail
cd "$(dirname "$0")"

WAZUH_VERSION=${1:-${WAZUH_VERSION:-4.14.7}}
IMAGE=${IMAGE:-triplesoc/wazuh-manager}

docker build --build-arg WAZUH_VERSION="$WAZUH_VERSION" -t "$IMAGE:$WAZUH_VERSION" .
docker run --rm --entrypoint grep "$IMAGE:$WAZUH_VERSION" -h 'default: triplesoc-' \
  /usr/share/filebeat/module/wazuh/alerts/manifest.yml /usr/share/filebeat/module/wazuh/archives/manifest.yml

echo "Imagen lista: $IMAGE:$WAZUH_VERSION"
if [[ "${PUSH:-0}" == 1 ]]; then docker push "$IMAGE:$WAZUH_VERSION"; fi
