# syntax=docker/dockerfile:1
# Imagen wazuh-dashboard con la capa visual TripleSOC.
# Para una actualización de seguridad: reconstruir con otra versión base,
#   ./build.sh 4.14.8
# La capa se vuelve a aplicar sobre la imagen oficial nueva; si Wazuh movió algún
# punto de marca obligatorio, el build falla en lugar de publicar la marca original.
ARG WAZUH_VERSION=4.14.7

FROM wazuh/wazuh-dashboard:${WAZUH_VERSION} AS base

# Etapa auxiliar: la imagen oficial no trae find/perl/rsvg, así que el parche
# se calcula aquí y solo los archivos modificados pasan a la imagen final.
FROM alpine:3.20 AS patcher
RUN apk add --no-cache bash coreutils findutils grep sed perl gettext rsvg-convert imagemagick font-dejavu gzip brotli
COPY --from=base /usr/share/wazuh-dashboard /src
COPY brand/ /brand/
COPY overlay/ /overlay/
COPY scripts/apply-branding.sh /usr/local/bin/apply-branding.sh
RUN bash /usr/local/bin/apply-branding.sh /src /out

FROM base
ARG WAZUH_VERSION
COPY --from=patcher --chown=wazuh-dashboard:wazuh-dashboard /out/ /usr/share/wazuh-dashboard/
LABEL org.opencontainers.image.title="triplesoc-wazuh-dashboard" \
      org.opencontainers.image.description="wazuh-dashboard ${WAZUH_VERSION} con la capa visual TripleSOC" \
      org.opencontainers.image.vendor="TripleCyber"

# Coolify ejecuta cada noche (02:00 UTC, "Forced Docker cleanup") un docker rmi de toda imagen
# sin esta etiqueta, aunque el compose la use con pull_policy: never. Con ella, la limpieza la respeta.
LABEL coolify.managed="true"
