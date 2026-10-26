#!/usr/bin/env bash
# Construye la imagen del servicio de respuesta.   ./build.sh [TAG]   (por defecto 0.13)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-0.13}
shift || true   # el resto de argumentos va a docker build (p. ej. --build-arg WITH_ANTHROPIC=1)
# Capa traductora: el contrato y su módulo viven en ../schema y se copian al contexto en cada build.
rm -rf .schema && mkdir .schema && cp ../schema/triplesoc-schema.json ../schema/tsoc_schema.py .schema/
# Imagen mínima: el script común que recorta Python vive en ../triplesoc-base.
rm -rf .base && mkdir .base && cp ../triplesoc-base/slim-rootfs.sh .base/
docker build "$@" -t "triplesoc/responder:$TAG" .
echo "Imagen lista: triplesoc/responder:$TAG"
