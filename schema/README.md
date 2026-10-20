# schema — capa traductora TripleSOC (fase 2)

TripleSOC no consulta Wazuh "a pelo". Los servicios y las pantallas piden a esta capa el índice de alertas, los nombres de campo y las bandas de severidad. Así, cuando Wazuh cambie su esquema (en 5.x, `wazuh-alerts-*` pasa a `wazuh-events-v5-*` y `rule.level` 0-16 pasa a 5 categorías), solo cambia el adaptador, y no todo el producto.

| Archivo | Quién lo usa |
|---|---|
| `triplesoc-schema.json` | **Contrato único**: índices, campos y bandas (critical ≥ 12, high 7-11, low < 7). |
| `tsoc_schema.py` | Responder, Incidents y Rulesmith (`import tsoc_schema as TS`). Su `build.sh` lo copia a la imagen. |
| `../triplesoc-dashboard/overlay/triplesoc-schema.js` | Pantallas del dashboard (`window.TSOC_SCHEMA`). `apply-branding.sh` incrusta el JSON y lo carga antes que los demás módulos. |

Escala de severidad: TripleSOC conserva siempre su escala 0-16. El adaptador `wazuh-4.x` la toma tal cual de `rule.level`. Un futuro adaptador `wazuh-5.x` traducirá las categorías nuevas a esa escala y reescribirá las consultas, sin tocar los servicios.

Lado productor, fuera de la capa a propósito porque es configuración de Wazuh 4.x: el prefijo de Filebeat (`triplesoc-manager/Dockerfile`), las reglas XML, el template y la ISM (`triplesoc-indexer/setup.sh`), el rol del indexer y el umbral de nivel de la integración de Teams.

Comprobaciones: `ops/schema-lint.sh` (sin literales sueltos), `ops/schema-test.py` / `.js` (set de oro) y la sección "Capa traductora" de `ops/upgrade-check.sh`.
