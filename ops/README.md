# ops — operación y actualizaciones de TripleSOC

Scripts del *Plan de Actualización Continua TripleSOC*. Se ejecutan en el servidor (crypto-dev-idp01) desde `/opt/triplesoc/src/ops`. Ninguno de los dos cambia el stack.

| Script | Fase | Qué hace |
|---|---|---|
| `upgrade-check.sh` | 1 | Comprueba en un minuto que todo lo propio sigue en pie: imágenes del compose (y su LABEL `coolify.managed`), contenedores healthy, `wazuh-analysisd -t`, reglas, decoders e integraciones instalados igual que en la imagen, Teams, alertas que llegan a `triplesoc-alerts-*` y ningún `wazuh-alerts-*` nuevo, el grupo `triplesoc-endpoints`, la marca del dashboard (5 módulos + CSS) y los servicios Responder, Incidents y Rulesmith junto con el receptor. Sale con código 0 si está **VERDE** y 1 si está **ROJO**. |
| `sbom.sh` | Transparencia | SBOM CycloneDX (Syft) + vulnerabilidades (Trivy) + resumen de licencias de cada imagen del compose. Deja el resultado en `/opt/triplesoc/sbom/<fecha>/RESUMEN.md`, con el enlace `ultimo`. |

```bash
cd /opt/triplesoc/src/ops
./upgrade-check.sh                 # stack de Coolify
SID=<id> ./upgrade-check.sh        # otro stack (canario)
./sbom.sh                          # todas las imágenes del compose
./sbom.sh triplesoc/wazuh-manager:4.14.8   # imágenes concretas
```

Regla de oro: **ninguna versión nueva de Wazuh pasa al stack si `upgrade-check.sh` no da VERDE en el canario**.
