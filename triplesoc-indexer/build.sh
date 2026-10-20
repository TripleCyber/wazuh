#!/usr/bin/env bash
# Construye triplesoc/wazuh-indexer (la oficial con la etiqueta de Coolify).   ./build.sh [WAZUH_VERSION]
# Variable opcional: IMAGE (default triplesoc/wazuh-indexer; ops/recibir-version.sh usa ...-cand).
set -euo pipefail
cd "$(dirname "$0")"
V=${1:-4.14.7}
IMAGE=${IMAGE:-triplesoc/wazuh-indexer}
docker build --build-arg WAZUH_VERSION="$V" -t "$IMAGE:$V" .
echo "Imagen lista: $IMAGE:$V"
