# TripleSOC Responder: recomienda la acción de respuesta por incidente (servicio aparte, no modifica Wazuh).
FROM python:3.12-alpine
RUN adduser -D -H -u 10001 tsoc && pip install --no-cache-dir anthropic
COPY responder.py /app/responder.py
USER tsoc
ENV PYTHONDONTWRITEBYTECODE=1
HEALTHCHECK --interval=60s --timeout=5s --start-period=120s --retries=3 \
  CMD find /tmp/heartbeat -mmin -3 | grep -q . || exit 1
CMD ["python", "-u", "/app/responder.py"]
LABEL org.opencontainers.image.title="triplesoc-responder" \
      org.opencontainers.image.vendor="TripleCyber"
# Coolify borra cada noche las imágenes sin esta etiqueta (ver triplesoc-dashboard/Dockerfile).
LABEL coolify.managed="true"
