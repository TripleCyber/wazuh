# Imagen wazuh-indexer de TripleSOC: la oficial SIN cambios, solo con la etiqueta de Coolify.
# Motivo: la limpieza nocturna de Coolify (02:00 UTC) hace docker rmi de toda imagen sin
# LABEL coolify.managed=true. Le quitó la etiqueta a wazuh/wazuh-indexer el 01-10, el 16-10 y el 20-10,
# y con pull_policy never un reinicio del stack habría fallado.
# Actualizar: ./build.sh 4.14.8 (y cambiar la etiqueta en el compose).
ARG WAZUH_VERSION=4.14.7
FROM wazuh/wazuh-indexer:${WAZUH_VERSION}
ARG WAZUH_VERSION
LABEL org.opencontainers.image.title="triplesoc-wazuh-indexer" \
      org.opencontainers.image.description="wazuh-indexer ${WAZUH_VERSION} oficial, sin cambios" \
      org.opencontainers.image.vendor="TripleCyber"
LABEL coolify.managed="true"
