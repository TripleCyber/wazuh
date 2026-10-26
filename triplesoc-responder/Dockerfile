# TripleSOC Responder: recomienda la acción de respuesta por incidente (servicio aparte, no modifica Wazuh).
# Etapa 1: el Python oficial de Alpine, recortado a lo justo por triplesoc-base/slim-rootfs.sh.
FROM python:3.12-alpine AS runtime
# El SDK de Anthropic solo hace falta con AI_PROVIDER=anthropic; con la API compatible (Groq) no se usa.
# Para incluirlo: ./build.sh <TAG> --build-arg WITH_ANTHROPIC=1
ARG WITH_ANTHROPIC=0
RUN if [ "$WITH_ANTHROPIC" = 1 ]; then pip install --no-cache-dir anthropic; fi
COPY .base/slim-rootfs.sh /slim-rootfs.sh
RUN sh /slim-rootfs.sh /rootfs
COPY responder.py /rootfs/app/responder.py
# Capa traductora (contrato de índices y campos): build.sh la copia desde ../schema.
COPY .schema/ /rootfs/app/

# Etapa 2: imagen final sin shell ni gestor de paquetes (sin BusyBox ni apk-tools, GPL-2.0).
FROM scratch
COPY --from=runtime /rootfs/ /
ENV PATH=/usr/local/bin LANG=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
USER tsoc
HEALTHCHECK --interval=60s --timeout=5s --start-period=120s --retries=3 \
  CMD ["python", "-c", "import os, sys, time; sys.exit(time.time() - os.path.getmtime('/tmp/heartbeat') > 180)"]
CMD ["python", "-u", "/app/responder.py"]
LABEL org.opencontainers.image.title="triplesoc-responder" \
      org.opencontainers.image.vendor="TripleCyber"
# Coolify borra cada noche las imágenes sin esta etiqueta (ver triplesoc-dashboard/Dockerfile).
LABEL coolify.managed="true"
