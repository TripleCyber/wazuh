#!/usr/bin/env bash
# Construye la imagen de la fábrica de reglas.   ./build.sh [TAG]   (por defecto 0.3)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-0.3}
docker build -t "triplesoc/rulesmith:$TAG" .
echo "Imagen lista: triplesoc/rulesmith:$TAG"
