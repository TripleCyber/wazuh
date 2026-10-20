#!/usr/bin/env bash
# Construye la imagen de la fábrica de reglas.   ./build.sh [TAG]   (por defecto 0.3)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-0.3}
# Capa traductora: el contrato y su módulo viven en ../schema y se copian al contexto en cada build.
rm -rf .schema && mkdir .schema && cp ../schema/triplesoc-schema.json ../schema/tsoc_schema.py .schema/
docker build -t "triplesoc/rulesmith:$TAG" .
echo "Imagen lista: triplesoc/rulesmith:$TAG"
