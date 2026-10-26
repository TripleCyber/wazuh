# Receptor de webhooks TripleSOC. Antes usaba python:3.12-alpine tal cual, y la limpieza nocturna
# de Coolify le quitaba la etiqueta (no tiene LABEL coolify.managed). Esta imagen la lleva.
# El compose sigue montando config/webhook-receiver.py en /app/receiver.py; la copia de aquí
# sirve para que la imagen funcione también sin el montaje.
# Etapa 1: el Python oficial de Alpine, recortado a lo justo por triplesoc-base/slim-rootfs.sh.
FROM python:3.12-alpine AS runtime
COPY .base/slim-rootfs.sh /slim-rootfs.sh
RUN sh /slim-rootfs.sh /rootfs
COPY receiver.py /rootfs/app/receiver.py

# Etapa 2: imagen final sin shell ni gestor de paquetes (sin BusyBox ni apk-tools, GPL-2.0).
# Sin shell, el healthcheck del compose tiene que ser de Python (ver deploy/docker-compose.yml).
FROM scratch
COPY --from=runtime /rootfs/ /
ENV PATH=/usr/local/bin LANG=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
CMD ["python", "-u", "/app/receiver.py"]
LABEL org.opencontainers.image.title="triplesoc-webhook-receiver" \
      org.opencontainers.image.vendor="TripleCyber"
LABEL coolify.managed="true"
