# TripleSOC Incidents: correlación de alertas en incidentes (servicio aparte, no modifica Wazuh).
FROM python:3.12-alpine
RUN adduser -D -H -u 10001 tsoc
COPY incidents.py /app/incidents.py
# Capa traductora (contrato de índices y campos): build.sh la copia desde ../schema.
COPY .schema/ /app/
USER tsoc
ENV PYTHONDONTWRITEBYTECODE=1
HEALTHCHECK --interval=60s --timeout=5s --start-period=120s --retries=3 \
  CMD find /tmp/heartbeat -mmin -3 | grep -q . || exit 1
CMD ["python", "-u", "/app/incidents.py"]
LABEL org.opencontainers.image.title="triplesoc-incidents" \
      org.opencontainers.image.vendor="TripleCyber"
# Coolify borra cada noche las imágenes sin esta etiqueta (ver triplesoc-dashboard/Dockerfile).
LABEL coolify.managed="true"
