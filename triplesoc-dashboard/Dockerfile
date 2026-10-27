# syntax=docker/dockerfile:1
# Imagen wazuh-dashboard con la capa visual TripleSOC.
# Para una actualización de seguridad: reconstruir con otra versión base,
#   ./build.sh 4.14.8
# La capa se vuelve a aplicar sobre la imagen oficial nueva; si Wazuh movió algún
# punto de marca obligatorio, el build falla en lugar de publicar la marca original.
#
# Sin los plugins de Wazuh (wazuh, wazuhCore, wazuhCheckUpdates; GPL-2.0) ni sus scripts de arranque: sus
# pantallas las sustituyen las de TripleSOC (overlay/triplesoc-endpoints-ui.js). Queda OpenSearch Dashboards
# (Apache-2.0) con sus plugins. WAZUH_PLUGINS=1 construye la variante anterior, con los plugins.
ARG WAZUH_VERSION=4.14.7

FROM wazuh/wazuh-dashboard:${WAZUH_VERSION} AS base

# Etapa auxiliar: la imagen oficial no trae find/perl/rsvg, así que el parche
# se calcula aquí y solo los archivos modificados pasan a la imagen final.
FROM alpine:3.20 AS patcher
ARG WAZUH_PLUGINS=0
RUN apk add --no-cache bash coreutils findutils grep sed perl gettext rsvg-convert imagemagick font-dejavu gzip brotli
COPY --from=base /usr/share/wazuh-dashboard /src
RUN if [ "$WAZUH_PLUGINS" != 1 ]; then rm -rf /src/plugins/wazuh /src/plugins/wazuhCore /src/plugins/wazuhCheckUpdates; fi
COPY brand/ /brand/
COPY overlay/ /overlay/
# Contrato de la capa traductora: build.sh lo copia desde ../schema (el contexto no puede salir de aquí).
COPY .schema/triplesoc-schema.json /schema/triplesoc-schema.json
COPY scripts/apply-branding.sh /usr/local/bin/apply-branding.sh
RUN bash /usr/local/bin/apply-branding.sh /src /out

FROM base AS assembled
ARG WAZUH_PLUGINS=0
COPY --from=patcher --chown=wazuh-dashboard:wazuh-dashboard /out/ /usr/share/wazuh-dashboard/
COPY --chmod=0755 triplesoc-entrypoint.sh /triplesoc-entrypoint.sh
USER root
RUN if [ "$WAZUH_PLUGINS" != 1 ]; then \
      rm -rf /usr/share/wazuh-dashboard/plugins/wazuh /usr/share/wazuh-dashboard/plugins/wazuhCore \
             /usr/share/wazuh-dashboard/plugins/wazuhCheckUpdates /entrypoint.sh /wazuh_app_config.sh; \
      ! ls -d /usr/share/wazuh-dashboard/plugins/wazuh* 2>/dev/null; \
    fi

# Imagen final en una sola capa: así los archivos borrados no siguen dentro de las capas de la imagen base.
FROM scratch
COPY --from=assembled / /
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    USER=wazuh-dashboard GROUP=wazuh-dashboard NAME=wazuh-dashboard INSTALL_DIR=/usr/share/wazuh-dashboard
USER wazuh-dashboard
WORKDIR /usr/share/wazuh-dashboard
EXPOSE 443
ENTRYPOINT ["/triplesoc-entrypoint.sh"]
ARG WAZUH_VERSION
LABEL org.opencontainers.image.title="triplesoc-wazuh-dashboard" \
      org.opencontainers.image.description="wazuh-dashboard ${WAZUH_VERSION} con la capa visual TripleSOC, sin los plugins de Wazuh" \
      org.opencontainers.image.vendor="TripleCyber"

# Coolify ejecuta cada noche (02:00 UTC, "Forced Docker cleanup") un docker rmi de toda imagen
# sin esta etiqueta, aunque el compose la use con pull_policy: never. Con ella, la limpieza la respeta.
LABEL coolify.managed="true"
