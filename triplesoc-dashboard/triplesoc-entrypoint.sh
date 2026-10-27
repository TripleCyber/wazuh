#!/bin/bash
# Arranque del panel TripleSOC: guarda las credenciales del indexer (usuario kibanaserver) en el keystore y
# lanza OpenSearch Dashboards. Sustituye a /entrypoint.sh y /wazuh_app_config.sh de la imagen de Wazuh
# (GPL-2.0), que además escribían la configuración del plugin de Wazuh, que esta imagen ya no lleva.
D=/usr/share/wazuh-dashboard
yes | "$D/bin/opensearch-dashboards-keystore" create --allow-root &&
  echo "${DASHBOARD_USERNAME:-kibanaserver}" | "$D/bin/opensearch-dashboards-keystore" add opensearch.username --stdin --allow-root &&
  echo "${DASHBOARD_PASSWORD:-kibanaserver}" | "$D/bin/opensearch-dashboards-keystore" add opensearch.password --stdin --allow-root
exec "$D/bin/opensearch-dashboards" -c "$D/config/opensearch_dashboards.yml"
