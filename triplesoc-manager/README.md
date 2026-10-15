# triplesoc-manager + triplesoc-indexer

Tubería de datos TripleSOC: las alertas se guardan en `triplesoc-alerts-AAAA.MM.DD`
en lugar de `wazuh-alerts-4.x-AAAA.MM.DD`.

```
wazuh-analysisd -> alerts.json -> Filebeat (módulo wazuh, index_prefix) -> pipeline de ingesta
  (date_index_name usa fields.index_prefix) -> indexer: triplesoc-alerts-* (template + ISM)
  -> dashboard: patrón triplesoc-alerts-*
```

| Pieza | Qué hace |
|---|---|
| `triplesoc-manager/Dockerfile` | Cambia el `index_prefix` por defecto del módulo Filebeat a `triplesoc-alerts-` / `triplesoc-archives-` (falla el build si el módulo cambió). |
| `triplesoc-manager/cont-init/1-triplesoc-filebeat` | En cada arranque deja `filebeat.yml` sin template legacy `wazuh` y sin overrides de prefijo. |
| `triplesoc-indexer/setup.sh` | Template componible `triplesoc-alerts` (derivado del template oficial del manager), política ISM `triplesoc-alerts-rotation`, migración y purga verificada de los índices antiguos. |

## Uso

```bash
cd triplesoc-manager && ./build.sh 4.14.7        # imagen triplesoc/wazuh-manager:4.14.7
# compose: wazuh-manager -> image 'triplesoc/wazuh-manager:4.14.7' + pull_policy: never
cd ../triplesoc-indexer
./setup.sh                 # template + ISM (antes de reiniciar el manager)
./setup.sh migrate         # copia el histórico wazuh-alerts-4.x-* -> triplesoc-alerts-*
./setup.sh purge-legacy    # borra lo antiguo solo si las copias están completas
RETENTION_DAYS=365 ./setup.sh   # opcional: añade borrado automático a la política
```

Dashboard: *Dashboard management → App settings → Index pattern* = `triplesoc-alerts-*`.

## Integración de webhooks (alertas nivel >= 12)

| Pieza | Qué hace |
|---|---|
| `integrations/custom-triplesoc.py` | Reestructura cada alerta al esquema `triplesoc.alert/v1` (`"vendor": "TripleSOC"`), reescribe "wazuh"/"ossec" en los textos y hace POST JSON. Incluye `text` para Slack/Teams. Log en `/var/ossec/logs/integrations.log`. |
| `integrations/custom-triplesoc` | Wrapper que usa el Python del manager. |
| `cont-init/1-triplesoc-integrations` | Instala script y reglas en los volúmenes en cada arranque (root:wazuh 750). |
| `rules/triplesoc_rules.xml` | Regla 100900 (nivel 12) para pruebas: se dispara con `TRIPLESOC_INTEGRATION_TEST`. |
| `../triplesoc-webhook-receiver/receiver.py` | Receptor interno de prueba (imprime cada webhook en sus logs). |

`ossec.conf` (archivo gestionado en Coolify):

```xml
<integration>
  <name>custom-triplesoc</name>
  <hook_url>http://triplesoc-webhook-receiver:8080/alerts</hook_url>  <!-- o la URL de Slack/Teams -->
  <level>12</level>
  <alert_format>json</alert_format>
</integration>
```

Prueba de punta a punta:

```bash
docker exec <manager> sh -c 'echo "$(date "+%b %d %H:%M:%S") lab TRIPLESOC_INTEGRATION_TEST" >> /var/ossec/logs/active-responses.log'
docker logs <triplesoc-webhook-receiver>
```

## Actualizar Wazuh

`./build.sh <versión>` en `triplesoc-manager` y `triplesoc-dashboard`, cambiar tags en el
compose, reiniciar y volver a ejecutar `triplesoc-indexer/setup.sh` (regenera el template
con las mappings de la nueva versión).
