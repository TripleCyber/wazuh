# syntax=docker/dockerfile:1
# wazuh-manager con la tubería de datos TripleSOC: Filebeat envía las alertas a
# índices triplesoc-alerts-AAAA.MM.DD en lugar de wazuh-alerts-4.x-*.
# Actualizar Wazuh: ./build.sh 4.14.8  (el build falla si el módulo cambió de forma).
ARG WAZUH_VERSION=4.14.7
FROM wazuh/wazuh-manager:${WAZUH_VERSION}
ARG WAZUH_VERSION
ARG ALERTS_PREFIX=triplesoc-alerts-
ARG ARCHIVES_PREFIX=triplesoc-archives-

# Prefijo por defecto del módulo Filebeat "wazuh" (vive en la imagen, no en el volumen /etc/filebeat).
RUN set -e; \
    for set in alerts:${ALERTS_PREFIX} archives:${ARCHIVES_PREFIX}; do \
      name=${set%%:*}; prefix=${set#*:}; \
      f=/usr/share/filebeat/module/wazuh/$name/manifest.yml; \
      grep -q 'name: index_prefix' "$f" || { echo "ERROR: index_prefix no encontrado en $f"; exit 1; }; \
      sed -i -E "/name: index_prefix/{n;s|default: .*|default: ${prefix}|}" "$f"; \
      grep -q "default: ${prefix}" "$f" || { echo "ERROR: no se pudo fijar el prefijo en $f"; exit 1; }; \
    done

# Ajuste de filebeat.yml en cada arranque (el archivo vive en un volumen): sin template legacy "wazuh".
COPY --chmod=0755 cont-init/1-triplesoc-filebeat /etc/cont-init.d/1-triplesoc-filebeat

# Integración de webhooks, reglas/decoders propios y grupo de endpoints (auditoría USB); se instalan en los volúmenes en cada arranque.
COPY integrations/ /opt/triplesoc/integrations/
COPY rules/ /opt/triplesoc/rules/
COPY decoders/ /opt/triplesoc/decoders/
COPY endpoints/ /opt/triplesoc/endpoints/
COPY --chmod=0755 cont-init/1-triplesoc-integrations /etc/cont-init.d/1-triplesoc-integrations
RUN "/var/ossec/framework/python/bin/python3" -m py_compile /opt/triplesoc/integrations/custom-triplesoc.py

LABEL org.opencontainers.image.title="triplesoc-wazuh-manager" \
      org.opencontainers.image.description="wazuh-manager ${WAZUH_VERSION} con índices triplesoc-alerts-*" \
      org.opencontainers.image.vendor="TripleCyber"

# Coolify ejecuta cada noche (02:00 UTC, "Forced Docker cleanup") un docker rmi de toda imagen
# sin esta etiqueta, aunque el compose la use con pull_policy: never. Con ella, la limpieza la respeta.
LABEL coolify.managed="true"
