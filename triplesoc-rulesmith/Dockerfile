# TripleSOC Rulesmith: la IA redacta reglas de Wazuh; una persona las aprueba en el dashboard.
# Etapa 1: el Python oficial de Alpine, recortado a lo justo por triplesoc-base/slim-rootfs.sh.
FROM python:3.12-alpine AS runtime
COPY .base/slim-rootfs.sh /slim-rootfs.sh
RUN sh /slim-rootfs.sh /rootfs
COPY rulesmith.py /rootfs/app/rulesmith.py
# Capa traductora (contrato de índices y campos): build.sh la copia desde ../schema.
COPY .schema/ /rootfs/app/
RUN python -m py_compile /rootfs/app/rulesmith.py

# Etapa 2: imagen final sin shell ni gestor de paquetes (sin BusyBox ni apk-tools, GPL-2.0).
FROM scratch
COPY --from=runtime /rootfs/ /
ENV PATH=/usr/local/bin LANG=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
USER tsoc
# Tras instalar reglas el ciclo espera el reinicio del manager (hasta ~4 min): margen amplio.
HEALTHCHECK --interval=60s --timeout=5s --start-period=120s --retries=3 \
  CMD ["python", "-c", "import os, sys, time; sys.exit(time.time() - os.path.getmtime('/tmp/heartbeat') > 480)"]
CMD ["python", "-u", "/app/rulesmith.py"]
LABEL org.opencontainers.image.title="triplesoc-rulesmith" \
      org.opencontainers.image.vendor="TripleCyber"
# Coolify borra cada noche las imágenes sin esta etiqueta (ver triplesoc-dashboard/Dockerfile).
LABEL coolify.managed="true"
