# TripleSOC sobre Wazuh — estado y traspaso (26/09/2026)

Entorno: Coolify → proyecto **Wazuh** → **dev** → servicio `wazuh-stack`.
Dashboard: https://wazuh-dashboard.idp.tripleenable.com (usuario `admin`).

## Asignaciones

| # | Asignación | Estado | Dónde verlo |
|---|---|---|---|
| 1 | Personalización de la interfaz + persistencia | ✅ Completa | Login y cualquier página del dashboard |
| 2 | Índices `triplesoc-alerts-*` | ✅ Completa | Indexer management → Index Management (Indexes, Templates, State management policies); Threat Hunting |
| 3 | Auditoría USB en endpoint | ⏸️ En pausa | Falta abrir TCP 1514/1515 en el NSG de Azure (VM crypto-dev-idp01, 20.65.219.193) |
| 4 | Webhook de alertas nivel ≥ 12 | ✅ Completa (receptor interno) | Coolify → wazuh-stack → Runtime Logs → Triplesoc Webhook Receiver |

## Código fuente (aquí y en el servidor en /opt/triplesoc/)

- `triplesoc-dashboard/` — imagen del dashboard con la capa visual (Dockerfile, apply-branding.sh, build.sh).
- `triplesoc-manager/` — imagen del manager: prefijo de índices, integración de webhooks, reglas.
- `triplesoc-indexer/setup.sh` — template, política de rotación, migración y purga verificada.
- `triplesoc-webhook-receiver/` — receptor interno de prueba.

## ¿Se pierden los cambios?

- **Reinicio / deploy:** no. Todo está en imágenes propias (`pull_policy: never`), archivos gestionados por Coolify y volúmenes.
- **Actualizar Wazuh:** no es automático. Procedimiento:
  ```bash
  cd /opt/triplesoc/triplesoc-dashboard && ./build.sh <versión>
  cd /opt/triplesoc/triplesoc-manager   && ./build.sh <versión>
  # cambiar los tags en el compose de Coolify, reiniciar (Force Restart si está Degraded)
  cd /opt/triplesoc/triplesoc-indexer && ./setup.sh
  ```
  Si una versión nueva cambia algo por dentro, el build falla y avisa (no publica la marca original).
- **No hacer:** "Run Docker Cleanup", `docker image prune -a`, cambiar las líneas `image:` a las oficiales.
- **Si se borraron las imágenes:** `./build.sh 4.14.7` en triplesoc-dashboard y triplesoc-manager.

## Probar el webhook

```bash
docker exec wazuh-manager-yf8u7icjiq4vdhetmea7rmfr sh -c 'echo "$(date "+%b %d %H:%M:%S") lab TRIPLESOC_INTEGRATION_TEST" >> /var/ossec/logs/active-responses.log'
```
Ver el mensaje en Runtime Logs del receptor (2–3 segundos).

## Pendientes / sugerencias

- Tarea 3 cuando abran el firewall (definir si los equipos son Windows, Linux o ambos).
- Teams: crear Workflow "Post to a channel when a webhook request is received" y pegar la URL en `<hook_url>` de `wazuh_manager.conf` (Coolify → Persistent Storage → Wazuh Manager → Files).
- Matices: textos "Wazuh" en datos; índices `wazuh-monitoring/statistics/states`.
- Profesionalizar: repositorio Git, registry privado de imágenes, alargar sesión del dashboard (hoy 15 min).

## Respaldos en el servidor

`/root/backup-wazuh-20260925-194003` (estado original), `/opt/triplesoc/backup-20260925-214021`,
`/opt/triplesoc/backup-20260925-233122-pipeline`, `/opt/triplesoc/backup-20260926-012619-integration`.
