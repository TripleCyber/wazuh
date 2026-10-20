# TripleSOC Rulesmith: la IA redacta reglas de Wazuh; una persona las aprueba en el dashboard.
FROM python:3.12-alpine
RUN adduser -D -H -u 10001 tsoc
COPY rulesmith.py /app/rulesmith.py
# Capa traductora (contrato de índices y campos): build.sh la copia desde ../schema.
COPY .schema/ /app/
RUN python -m py_compile /app/rulesmith.py
USER tsoc
ENV PYTHONDONTWRITEBYTECODE=1
# Tras instalar reglas el ciclo espera el reinicio del manager (hasta ~4 min): margen amplio.
HEALTHCHECK --interval=60s --timeout=5s --start-period=120s --retries=3 \
  CMD find /tmp/heartbeat -mmin -8 | grep -q . || exit 1
CMD ["python", "-u", "/app/rulesmith.py"]
LABEL org.opencontainers.image.title="triplesoc-rulesmith" \
      org.opencontainers.image.vendor="TripleCyber"
# Coolify borra cada noche las imágenes sin esta etiqueta (ver triplesoc-dashboard/Dockerfile).
LABEL coolify.managed="true"
