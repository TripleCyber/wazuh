#!/usr/bin/env bash
# Construye el BFF.   ./build.sh [TAG]   (por defecto 0.1)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-0.1}
# Capa traductora: el contrato y su módulo viven en ../schema y se copian al contexto en cada build.
rm -rf .schema && mkdir .schema && cp ../schema/triplesoc-schema.json ../schema/tsoc_schema.py .schema/
docker build -t "triplesoc/bff:$TAG" .
echo "Imagen lista: triplesoc/bff:$TAG"
