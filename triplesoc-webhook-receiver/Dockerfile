# Receptor de webhooks TripleSOC. Antes usaba python:3.12-alpine tal cual, y la limpieza nocturna
# de Coolify le quitaba la etiqueta (no tiene LABEL coolify.managed). Esta imagen la lleva.
# El compose sigue montando config/webhook-receiver.py en /app/receiver.py; la copia de aquí
# sirve para que la imagen funcione también sin el montaje.
FROM python:3.12-alpine
COPY receiver.py /app/receiver.py
ENV PYTHONDONTWRITEBYTECODE=1
CMD ["python", "-u", "/app/receiver.py"]
LABEL org.opencontainers.image.title="triplesoc-webhook-receiver" \
      org.opencontainers.image.vendor="TripleCyber"
LABEL coolify.managed="true"
