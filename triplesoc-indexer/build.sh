#!/usr/bin/env bash
# Construye triplesoc/wazuh-indexer (la oficial con la etiqueta de Coolify).   ./build.sh [WAZUH_VERSION]
set -euo pipefail
cd "$(dirname "$0")"
V=${1:-4.14.7}
docker build --build-arg WAZUH_VERSION="$V" -t "triplesoc/wazuh-indexer:$V" .
echo "Imagen lista: triplesoc/wazuh-indexer:$V"
