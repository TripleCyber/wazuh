#!/usr/bin/env bash
# Construye la imagen del servicio de respuesta.   ./build.sh [TAG]   (por defecto 0.13)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-0.13}
docker build -t "triplesoc/responder:$TAG" .
echo "Imagen lista: triplesoc/responder:$TAG"
