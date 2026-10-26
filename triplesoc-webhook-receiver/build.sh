#!/usr/bin/env bash
# Construye el receptor de webhooks.   ./build.sh [TAG]   (por defecto 1.0)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-1.0}
# Imagen mínima: el script común que recorta Python vive en ../triplesoc-base.
rm -rf .base && mkdir .base && cp ../triplesoc-base/slim-rootfs.sh .base/
docker build -t "triplesoc/webhook-receiver:$TAG" .
echo "Imagen lista: triplesoc/webhook-receiver:$TAG"
