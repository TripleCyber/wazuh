# Cambios

Historial de TripleSOC por fecha. El detalle de cada cambio está en `git log`.

## 2026-10-26 — Servicios propios sin componentes GPL

- **Imagen mínima** para incidents 1.2, responder 0.18, rulesmith 0.5, webhook-receiver 1.1 y BFF 0.2
  (`triplesoc-base/slim-rootfs.sh`): parte de `scratch` con el mismo Python 3.12 de Alpine, sin BusyBox ni apk-tools
  (GPL-2.0) y sin los módulos readline, gdbm, dbm y nis. 58 MB en lugar de 74-143 MB.
- Cada imagen lleva `/usr/share/triplesoc/librerias-sistema.txt` (librería, paquete y licencia); la construcción
  falla si entra una librería GPL.
- Healthchecks en Python (la imagen no tiene shell). El SDK de Anthropic del Responder es opcional
  (`--build-arg WITH_ANTHROPIC=1`); con Groq no hace falta.
- `upgrade-check.sh`: las comprobaciones dentro de los contenedores usan Python, y distingue los índices de alertas de
  más de 30 días (la política ISM los deja en solo lectura a propósito) de un bloqueo real.
- Desplegado y verificado en dev: canario VERDE (set de oro 99,88 %) y `upgrade-check` VERDE.

## 2026-10-22 — Portal de entrada, acceso por rol y despliegue documentado

- **Portal "Cúpula · noche"** (elegido por Vladimir): tarjeta con ciudad protegida por una cúpula (imagen fija y nítida),
  logo oficial, "Hi Analyst" y un único botón **Sign in with TripleEnable**. Sin indicador "Live".
- **Arranque temprano del portal** desde `bootstrap.js`: al recargar ya no se ven "Loading..." ni el login nativo.
- **Login local de respaldo** en `/app/login#local` (el servidor rechaza `?local` con 400).
- **Acceso solo con rol de TripleSOC**: reglas RBAC de la API de Wazuh para los roles de Logto (`ops/oidc/wazuh-rbac.sh`)
  y pantalla **Access not granted** para cuentas sin rol.
- **README** con el procedimiento completo para levantarlo y **`deploy/`** con el docker-compose limpio, plantillas de
  configuración sin secretos y `generate-certs.sh`.

## 2026-10-21 — Login único con TripleEnable (Logto)

- OpenID Connect en el dashboard y en el indexer (`ops/oidc/indexer-oidc.sh`), identificando al usuario por `sub`.
- Validación del id_token ES384 de Logto con el validador `jwt` del indexer (`ops/oidc/indexer-jwt-ec.sh`).
- Cerrar sesión sigue la redirección de Logto.
- Número de build propio en cada imagen del dashboard: el navegador deja de usar la capa anterior.

## 2026-10-20 — Fases 2 y 3 del plan de actualizaciones seguras

- **Capa traductora** (`schema/triplesoc-schema.json`, contrato `triplesoc.schema/v1`) usada por dashboard y servicios.
- **Política de parches** y registro de CVE del SBOM (`ops/POLITICA-PARCHES.md`, `ops/registro-parches.md`).
- **Canario** (`ops/canary.sh`) y **`ops/recibir-version.sh`**: única puerta para versiones nuevas de Wazuh, con respaldo,
  canario, promoción, verificación y vuelta atrás automática.
- **Set de oro** (`ops/golden/`): etiquetas del analista, casos sintéticos, muestreador y evaluador.
- `upgrade-check.sh` vigila el disco del indexer y los bloqueos del clúster.
- Responder 0.17 (guardarraíl de inyección), BFF prototipo, inventario de licencias.
- Imágenes envoltorio con `LABEL coolify.managed` (la limpieza nocturna de Coolify ya no las borra).
- Dashboard: botón **Cerrar sesión** en la tarjeta de usuario del menú lateral.

## 2026-10-16 — Operación

- `ops/upgrade-check.sh` (comprobación de solo lectura tras cualquier cambio) y `ops/sbom.sh` (SBOM, CVE y licencias).
- Guardarraíles de IA contra inyección de prompts: reglas 100940-100943 y techo de severidad en el Responder.

## 2026-10-15 — Primera versión en git

Estado desplegado hasta esa fecha (sobre Wazuh 4.14.7):

- Capa visual del dashboard: marca TripleSOC, Security Overview, menú propio, pantallas **Incidents**, **AI Rules**
  y **Guardian**, asistente flotante con chat y voz.
- Tubería `triplesoc-alerts-*` (template, ISM, migración) y reglas/decoders propios en el manager.
- Integración de webhooks (alertas ≥ 12) y avisos en Microsoft Teams con el id del evento.
- Servicios: **Incidents** (correlación), **Responder** (respuesta con aprobación, Undo/Retry e IA),
  **Rulesmith** (reglas redactadas con IA e instaladas tras aprobación), receptor de webhooks.
- Endpoints Windows: instalador del agente, auditoría y bloqueo USB, carril rápido de ratón/teclado y teléfonos.
