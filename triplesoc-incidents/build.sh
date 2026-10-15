#!/usr/bin/env bash
# Construye la imagen del servicio de incidentes.   ./build.sh [TAG]   (por defecto 1.0)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-1.0}
docker build -t "triplesoc/incidents:$TAG" .
echo "Imagen lista: triplesoc/incidents:$TAG"
