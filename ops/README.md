# ops — operación y actualizaciones de TripleSOC

Scripts del *Plan de Actualización Continua TripleSOC*. Se ejecutan en el servidor (crypto-dev-idp01) desde `/opt/triplesoc/src/ops`. Ninguno cambia el stack.

| Script | Fase | Qué hace |
|---|---|---|
| `upgrade-check.sh` | 1 | Comprueba en un minuto que todo lo propio sigue en pie: imágenes del compose (y su LABEL `coolify.managed`), contenedores healthy, `wazuh-analysisd -t`, reglas, decoders e integraciones instalados igual que en la imagen, Teams, alertas que llegan a `triplesoc-alerts-*` y ningún `wazuh-alerts-*` nuevo, el grupo `triplesoc-endpoints`, la marca del dashboard (6 módulos, incluida la capa traductora, + CSS), el contrato de esquema en cada servicio y los servicios Responder, Incidents y Rulesmith junto con el receptor. Sale con código 0 si está **VERDE** y 1 si está **ROJO**. |
| `sbom.sh` | Transparencia | SBOM CycloneDX (Syft) + vulnerabilidades (Trivy) + resumen de licencias de cada imagen del compose. Deja el resultado en `/opt/triplesoc/sbom/<fecha>/RESUMEN.md`, con el enlace `ultimo`. |
| `schema-lint.sh` | 2 | Vigilante de la capa traductora: falla si un servicio o pantalla vuelve a escribir a mano el índice de alertas o un campo de Wazuh (`rule.level`, `agent.name`...). |
| `schema-test.py` · `schema-test.js` | 2 | Set de oro: con el adaptador 4.x, la capa produce exactamente las consultas que antes estaban escritas a mano (Python en cada imagen de servicio y JS con el node del dashboard). |
| `POLITICA-PARCHES.md` · `registro-parches.md` · `PLANTILLA-SBOM.md` | Transparencia | Plazos (críticas ≤ 72 h), cómo se aplica un parche, excepciones, registro y ficha SBOM por versión. |

```bash
cd /opt/triplesoc/src/ops
./upgrade-check.sh                 # stack de Coolify
SID=<id> ./upgrade-check.sh        # otro stack (canario)
./sbom.sh                          # todas las imágenes del compose
./sbom.sh triplesoc/wazuh-manager:4.14.8   # imágenes concretas
./schema-lint.sh                   # capa traductora sin literales sueltos
docker run --rm --network none -v /opt/triplesoc/src/ops:/t:ro triplesoc/responder:<tag> python /t/schema-test.py responder
```

Regla de oro: **ninguna versión nueva de Wazuh pasa al stack si `upgrade-check.sh` no da VERDE en el canario**.
