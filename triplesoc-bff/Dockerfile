# TripleSOC BFF (prototipo): API propia para el frontend, solo lectura, sin campos de Wazuh.
FROM python:3.12-alpine
RUN adduser -D -H -u 10001 tsoc
COPY bff.py /app/bff.py
# Capa traductora (contrato de índices y campos): build.sh la copia desde ../schema.
COPY .schema/ /app/
RUN python -m py_compile /app/bff.py
USER tsoc
ENV PYTHONDONTWRITEBYTECODE=1
EXPOSE 8090
HEALTHCHECK --interval=60s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8090/api/v1/health | grep -q '"status": "ok"' || exit 1
CMD ["python", "-u", "/app/bff.py"]
LABEL org.opencontainers.image.title="triplesoc-bff" \
      org.opencontainers.image.vendor="TripleCyber"
# Coolify borra cada noche las imágenes sin esta etiqueta (ver triplesoc-dashboard/Dockerfile).
LABEL coolify.managed="true"
