#!/usr/bin/env bash
# Construye la imagen del servicio de incidentes.   ./build.sh [TAG]   (por defecto 1.0)
set -euo pipefail
cd "$(dirname "$0")"
TAG=${1:-1.0}
# Capa traductora: el contrato y su módulo viven en ../schema y se copian al contexto en cada build.
rm -rf .schema && mkdir .schema && cp ../schema/triplesoc-schema.json ../schema/tsoc_schema.py .schema/
# Imagen mínima: el script común que recorta Python vive en ../triplesoc-base.
rm -rf .base && mkdir .base && cp ../triplesoc-base/slim-rootfs.sh .base/
docker build -t "triplesoc/incidents:$TAG" .
echo "Imagen lista: triplesoc/incidents:$TAG"
