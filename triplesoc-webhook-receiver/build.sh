#!/usr/bin/env bash
# Construye el receptor de webhooks.   ./build.sh [TAG]   (por defecto 1.0)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-1.0}
docker build -t "triplesoc/webhook-receiver:$TAG" .
echo "Imagen lista: triplesoc/webhook-receiver:$TAG"
