# TripleSOC BFF (prototipo): API propia para el frontend, solo lectura, sin campos de Wazuh.
# Etapa 1: el Python oficial de Alpine, recortado a lo justo por triplesoc-base/slim-rootfs.sh.
FROM python:3.12-alpine AS runtime
COPY .base/slim-rootfs.sh /slim-rootfs.sh
RUN sh /slim-rootfs.sh /rootfs
COPY bff.py /rootfs/app/bff.py
# Capa traductora (contrato de índices y campos): build.sh la copia desde ../schema.
COPY .schema/ /rootfs/app/
RUN python -m py_compile /rootfs/app/bff.py

# Etapa 2: imagen final sin shell ni gestor de paquetes (sin BusyBox ni apk-tools, GPL-2.0).
FROM scratch
COPY --from=runtime /rootfs/ /
ENV PATH=/usr/local/bin LANG=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
USER tsoc
EXPOSE 8090
HEALTHCHECK --interval=60s --timeout=5s --start-period=20s --retries=3 \
  CMD ["python", "-c", "import sys, urllib.request; b = urllib.request.urlopen('http://127.0.0.1:8090/api/v1/health', timeout=4).read(); sys.exit(b'\"status\": \"ok\"' not in b)"]
CMD ["python", "-u", "/app/bff.py"]
LABEL org.opencontainers.image.title="triplesoc-bff" \
      org.opencontainers.image.vendor="TripleCyber"
# Coolify borra cada noche las imágenes sin esta etiqueta (ver triplesoc-dashboard/Dockerfile).
LABEL coolify.managed="true"
