# Estado del entorno de desarrollo (26-10-2026)

Para instalar desde cero: [README.md](README.md). Historial: [CHANGELOG.md](CHANGELOG.md).

## Dónde corre

- Coolify → proyecto **Wazuh** → entorno **dev** → servicio `wazuh-stack`.
- Dashboard: https://wazuh-dashboard.idp.tripleenable.com (Sign in with TripleEnable; respaldo `/app/login#local`).
- Copia de trabajo del código en el servidor: `/opt/triplesoc/src` (misma rama que GitHub `develop`).

## Versiones desplegadas

| Servicio | Imagen | Notas |
|---|---|---|
| wazuh-indexer | `triplesoc/wazuh-indexer:4.14.7` | Oficial + etiqueta de Coolify |
| wazuh-manager | `triplesoc/wazuh-manager:4.14.7` | Reglas, decoders, integración, Filebeat a `triplesoc-alerts-*` |
| wazuh-dashboard | `triplesoc/wazuh-dashboard:4.14.7` | `triplesoc-dashboard/build.sh 4.14.7`: sin los plugins de Wazuh (GPL); pantallas propias Entities, Trust Zones, Attack Map y APIs |
| triplesoc-incidents | `triplesoc/incidents:1.3` | Imagen mínima (scratch, sin BusyBox ni apk) |
| triplesoc-responder | `triplesoc/responder:0.20` | `MODE=approve`, IA por Groq; imagen mínima; inventario de equipos cada 5 min |
| triplesoc-rulesmith | `triplesoc/rulesmith:0.6` | `MODE=install`; imagen mínima |
| triplesoc-webhook-receiver | `triplesoc/webhook-receiver:1.2` | Imagen mínima |

Comprobación: `ops/upgrade-check.sh` en el servidor. El 26-10 sale VERDE (60 OK y un aviso: disco al 81 %).

Coolify 4.5.0 reescribe el compose entero al guardar en "Edit Compose File" (añade variables `COOLIFY_*`, monta en
solo lectura los bind mounts marcados `:ro` y cambia las etiquetas de Traefik del panel). El indexer, el manager y el
panel tomarán ese formato en su próximo reinicio.

## Qué vive fuera de git (a propósito)

Contraseñas (`.env` de Coolify), `client_secret` de Logto (Files de `opensearch_dashboards.yml`), certificados,
URL de Teams y claves de IA (`/opt/triplesoc/*-secrets`, `/opt/triplesoc/responder-teams`).

## Pendientes

- Prueba real del acceso por rol: tsoc-admin con las pantallas de Wazuh y una cuenta sin rol ("Access not granted").
- Disco del servidor al 81 %: ampliar o limpiar imágenes antiguas (al 90 % el indexer bloquea índices nuevos).
- Pipelines y `main` como producción (propuesta de Fausto).
- Instalación completa desde cero siguiendo solo el README, en una máquina limpia.

## Respaldos en el servidor

- Imágenes anteriores del dashboard: `triplesoc/wazuh-dashboard:fase2-nolive-20261022`, `fase2-noche-live-20261022`,
  `fase2-atardecer-20261022`, `fase2-aurora-20261022`, `fase2-escudo-20261022`, `fase2-backup-20261022`.
- Volver atrás una imagen: `docker tag <respaldo> triplesoc/wazuh-dashboard:fase2` y
  `docker compose --env-file .env -p <id> up -d --no-deps wazuh-dashboard` en `/data/coolify/services/<id>`.
- Copias del compose y de la configuración: `/opt/triplesoc/backup-*`.
