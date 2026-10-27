# TripleSOC

Plataforma SOC de TripleCyber construida **sobre Wazuh 4.14.7** (single-node). No es un fork del código de Wazuh:
se parte de las imágenes oficiales y se les añade una capa propia (marca, pantallas, reglas, tubería de datos) más
servicios TripleSOC que corren al lado.

| Componente | Carpeta | Qué hace |
|---|---|---|
| **Indexer** | `triplesoc-indexer/` | Imagen oficial + `setup.sh`: plantilla e ISM de los índices `triplesoc-alerts-*`. |
| **Manager** | `triplesoc-manager/` | Reglas y decoders TripleSOC, integración de webhooks (`custom-triplesoc`), Filebeat hacia `triplesoc-alerts-*`, scripts de agentes Windows. |
| **Dashboard** | `triplesoc-dashboard/` | Capa visual TripleSOC: portal de entrada "Sign in with TripleEnable", Security Overview, Incidents, AI Rules, Guardian y asistente. |
| **Incidents** | `triplesoc-incidents/` | Correlación: agrupa alertas en incidentes (`triplesoc-incidents*`). |
| **Responder** | `triplesoc-responder/` | Propone o ejecuta respuestas de un catálogo cerrado (bloqueo USB, etc.), con aprobación, Undo y avisos a Teams. |
| **Rulesmith** | `triplesoc-rulesmith/` | Redacta reglas Wazuh a partir de lo que se pide en *AI Rules*, las valida y las instala aprobadas. |
| **Webhook receiver** | `triplesoc-webhook-receiver/` | Receptor interno de las alertas de nivel ≥ 12. |
| **BFF** | `triplesoc-bff/` | API propia de solo lectura (prototipo; no está en el compose). |
| **Esquema** | `schema/` | Contrato común de índices y campos (`triplesoc.schema/v1`) que usan dashboard y servicios. |
| **Operación** | `ops/` | Comprobación tras cambios (`upgrade-check.sh`), recepción de versiones de Wazuh, login con Logto, RBAC, SBOM. |
| **Despliegue** | `deploy/` | `docker-compose.yml` limpio, plantillas de configuración y generador de certificados. |

---

## Requisitos

- Linux x86_64 con **Docker 24+**, **Docker Compose v2** (`docker compose version`) y `openssl`.
- **8 GB de RAM** como mínimo (límites: indexer 4 GB, manager 2 GB, dashboard 1,5 GB, servicios ~0,6 GB) y **50 GB de disco libre**.
  El indexer bloquea índices nuevos al 90 % de disco: vigilarlo (`upgrade-check.sh` avisa).
- `vm.max_map_count` ≥ 262144 en el host (lo exige el indexer):
  ```bash
  echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-wazuh.conf && sudo sysctl --system
  ```
- Puertos abiertos hacia los equipos con agente: **1514/tcp** (eventos) y **1515/tcp** (registro).
- Un dominio y un **proxy con HTTPS** delante del dashboard (Coolify/Traefik, Caddy, Nginx...). El login con Logto no funciona sin HTTPS.
- Para la IA del Responder y Rulesmith: una clave de API compatible con OpenAI (Groq por defecto). Sin clave, el Responder decide solo con su tabla fija, Rulesmith no redacta borradores y el chat del Guardian no contesta. (El Responder y Rulesmith también admiten `AI_PROVIDER=anthropic`, pero el chat del Guardian solo usa la API compatible con OpenAI.)

---

## Levantar TripleSOC

Todos los comandos se ejecutan en el servidor, como un usuario con permisos de Docker (y `sudo` donde se indica).

### 1. Descargar el código

```bash
git clone -b develop https://github.com/TripleCyber/wazuh.git triplesoc
cd triplesoc
```

### 2. Construir las imágenes

Todas las imágenes son locales (`pull_policy: never`): hay que construirlas antes del primer arranque y con estas etiquetas,
que son las que usa `deploy/docker-compose.yml`. El dashboard tarda unos minutos.

```bash
(cd triplesoc-indexer          && ./build.sh 4.14.7)
(cd triplesoc-manager          && ./build.sh 4.14.7)
(cd triplesoc-dashboard        && ./build.sh 4.14.7)
(cd triplesoc-incidents        && ./build.sh 1.3)
(cd triplesoc-responder        && ./build.sh 0.19)
(cd triplesoc-rulesmith        && ./build.sh 0.6)
(cd triplesoc-webhook-receiver && ./build.sh 1.2)
docker images 'triplesoc/*'
```

Cada imagen lleva la etiqueta `coolify.managed=true`: así la limpieza automática de Coolify no las borra.

### 3. Configurar (secretos fuera de git)

```bash
cd deploy
cp .env.example .env
cp config/wazuh_indexer/internal_users.yml.example         config/wazuh_indexer/internal_users.yml
cp config/wazuh_dashboard/wazuh.yml.example                config/wazuh_dashboard/wazuh.yml
cp config/wazuh_dashboard/opensearch_dashboards.yml.example config/wazuh_dashboard/opensearch_dashboards.yml
cp config/wazuh_cluster/authd.pass.example                 config/wazuh_cluster/authd.pass
```

Después, cambiar **todos** los valores `CAMBIAR-*`:

| Archivo | Qué poner |
|---|---|
| `.env` | `INDEXER_PASSWORD`, `DASHBOARD_PASSWORD`, `API_PASSWORD` (mayúscula, minúscula, número y símbolo) y `SID` si se quiere otro nombre. |
| `config/wazuh_indexer/internal_users.yml` | El **hash** de `INDEXER_PASSWORD` en `admin` y el de `DASHBOARD_PASSWORD` en `kibanaserver` (ver abajo). Las demás cuentas de demo se pueden borrar. |
| `config/wazuh_dashboard/wazuh.yml` | `password` = el mismo `API_PASSWORD`. |
| `config/wazuh_cluster/authd.pass` | Contraseña para registrar agentes (la pedirá el instalador de Windows). |
| `config/wazuh_dashboard/opensearch_dashboards.yml` | Datos de Logto (`client_id`, `client_secret`, dominio) o borrar el bloque final si no se usa Logto. |

Generar un hash para `internal_users.yml` (repetir para cada contraseña):

```bash
docker run --rm -ti triplesoc/wazuh-indexer:4.14.7 \
  bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh
```

> Las contraseñas del indexer se aplican **en el primer arranque**. Cambiarlas después exige `securityadmin`
> (ver la documentación de Wazuh, "Changing the default password").

### 4. Generar los certificados TLS internos

```bash
sudo ./generate-certs.sh
```

Crea en `certs/` una CA propia y los certificados de indexer, manager, dashboard y admin (10 años), con los nombres
de host del compose. Al final verifica cada certificado contra la CA (`OK`). Si ya existe una CA, no toca nada.

### 5. Arrancar

```bash
docker compose up -d
docker compose ps        # esperar a que indexer, manager y dashboard estén "healthy" (2-4 minutos)
```

Incidents, Responder y Rulesmith se reinician en bucle hasta el paso 6 (todavía no tienen sus usuarios): es normal.

### 6. Crear los usuarios de servicio

Cada script crea un usuario con permisos mínimos y deja su contraseña en `deploy/secrets/` (dueño 10001, modo 400).
Nunca la imprime. Se pueden repetir sin problema.

```bash
SID=$(grep ^SID= .env | cut -d= -f2)

# Índices triplesoc-alerts-* (plantilla + rotación). Antes de que lleguen alertas.
INDEXER=wazuh-indexer-$SID MANAGER=wazuh-manager-$SID ../triplesoc-indexer/setup.sh

# Usuario del indexer para Incidents, Responder y Rulesmith.
sudo SECRET_DIR=$PWD/secrets/indexer   ../triplesoc-incidents/setup-indexer-user.sh wazuh-indexer-$SID

# Usuario de la API de Wazuh para que el Responder ejecute respuestas.
sudo SECRET_DIR=$PWD/secrets/responder ../triplesoc-responder/setup-api-user.sh  wazuh-manager-$SID
```

Usuario de Rulesmith: se crea en el dashboard (*Security*), con las políticas y el rol que lista
`triplesoc-rulesmith/README.md` ("Fase B"). Su contraseña va en `secrets/rulesmith/wazuh_api_password`.

Clave de IA (opcional, la comparten Responder y Rulesmith):

```bash
sudo sh -c 'umask 077; cat > secrets/responder/ai_api_key'   # pegar la clave, Enter, Ctrl+D
sudo chown 10001 secrets/responder/ai_api_key && sudo chmod 400 secrets/responder/ai_api_key
```

Reiniciar los servicios para que lean sus secretos:

```bash
docker compose restart triplesoc-incidents triplesoc-responder triplesoc-rulesmith
```

### 7. Primer acceso al dashboard

1. Publicar `127.0.0.1:5601` con el proxy HTTPS y abrir el dominio.
2. Entrar con **Sign in with TripleEnable** (Logto) o, de respaldo, en `https://<dominio>/app/login#local` con `admin` / `INDEXER_PASSWORD`.
3. Patrón de índices: *Dashboard management → App settings → Index pattern* = `triplesoc-alerts-*`.
4. Pantallas Security Overview, Incidents, AI Rules y Guardian: con la sesión iniciada como admin, pegar en la consola del
   navegador (F12) cada archivo de `triplesoc-dashboard/saved-objects/`. Crean sus objetos guardados; se pueden repetir.

### 8. Login con TripleEnable (Logto) y roles

Solo si se usa Logto. Los scripts respaldan la configuración antes de tocarla y se pueden repetir.

```bash
cd ..   # raíz del repo
SID=triplesoc ops/oidc/indexer-oidc.sh     # el indexer acepta los usuarios de Logto y mapea sus roles
SID=triplesoc ops/oidc/indexer-jwt-ec.sh   # valida los tokens ES384 de Logto (repetir si Logto rota su clave)
SID=triplesoc ops/oidc/wazuh-rbac.sh       # roles de Logto -> permisos de la API de Wazuh
```

Roles en Logto (claim `roles`): `tsoc-admin` (administrador), `tsoc-analista` y `tsoc-lectura` (lectura).
Una cuenta sin rol entra pero ve **"Access not granted"**.

### 9. Comprobar que todo funciona

```bash
SID=triplesoc SVC_DIR=$PWD/deploy ops/upgrade-check.sh
```

Solo lee, no cambia nada. Cada comprobación sale OK / WARN / FAIL; al final, **VERDE** o **ROJO**.
Prueba de punta a punta de las alertas: `triplesoc-manager/README.md`, "Integración de webhooks".

---

## Agentes (equipos a vigilar)

En cada equipo Windows, PowerShell **como administrador**:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-agent-windows.ps1
```

El script está en `triplesoc-manager/endpoints/`. Pide la contraseña de `authd.pass` y une el equipo al grupo
`triplesoc-endpoints`. Para las respuestas automáticas, ejecutar también `install-response-scripts.ps1`.

## Avisos en Teams (opcional)

La URL del Workflow de Teams es secreta y no va en ningún archivo de git:

```bash
SID=$(grep ^SID= deploy/.env | cut -d= -f2)
# Manager (alertas de nivel >= 12):
docker exec -i wazuh-manager-$SID sh -c 'cat > /var/ossec/etc/triplesoc-teams.url && chown root:wazuh /var/ossec/etc/triplesoc-teams.url && chmod 640 /var/ossec/etc/triplesoc-teams.url'
# Responder (tarjetas con aprobar / deshacer):
sudo sh -c 'mkdir -p deploy/secrets/teams; umask 077; cat > deploy/secrets/teams/triplesoc-teams.url'
sudo chown -R 10001 deploy/secrets/teams
```

(En cada `cat >`: pegar la URL, Enter, Ctrl+D.)

---

## Despliegue en Coolify

El entorno de desarrollo actual corre en Coolify como un *Docker Compose* service. Diferencias con `deploy/`:

- Coolify añade su red, sus etiquetas y el sufijo del servicio a los nombres (`wazuh-indexer-<id>`). Los scripts usan `SID=<id>`.
- Los archivos de `config/` y `certs/` viven en `/data/coolify/services/<id>/` y se editan en la pestaña *Files*.
- Las contraseñas de `.env` se ponen en *Environment Variables*.
- El dominio del dashboard se asigna en el servicio `wazuh-dashboard` (puerto 5601); Coolify pone el HTTPS.
- No usar "Restart" de Coolify para un cambio de imagen: `docker compose -p <id> up -d --no-deps <servicio>`.

## Operación

| Tarea | Cómo |
|---|---|
| Ver estado | `docker compose ps` y `SID=... ops/upgrade-check.sh` |
| Logs de un servicio | `docker compose logs -f --tail 100 triplesoc-responder` |
| Desplegar un cambio propio | Reconstruir esa imagen y `docker compose up -d --no-deps <servicio>` |
| Cambio en el dashboard | `cd triplesoc-dashboard && ./build.sh 4.14.7`, luego `up -d --no-deps wazuh-dashboard` |
| Actualizar Wazuh (4.14.x) | `ops/recibir-version.sh` (única puerta: canario, comprobación y vuelta atrás). Ver `ops/README.md` y `ops/POLITICA-PARCHES.md` |
| Volver atrás una imagen | Antes de cada cambio: `docker tag <imagen>:<tag> <imagen>:<tag>-respaldo`; para volver, retag y `up -d --no-deps` |

**Wazuh 5.x no es compatible todavía**: cambia reglas, active response e índices. No actualizar sin plan.

## Problemas frecuentes

| Síntoma | Causa y solución |
|---|---|
| El indexer se reinicia en bucle | `vm.max_map_count` bajo, o poca RAM. Ver Requisitos. |
| `pull access denied for triplesoc/...` | Falta construir esa imagen o la etiqueta no coincide con el compose (paso 2). |
| Dashboard: "Wazuh API seems to be down" | `password` de `wazuh.yml` distinta de `API_PASSWORD`, o el manager aún arranca. |
| Dashboard no entra con `admin` | El hash de `internal_users.yml` no corresponde a `INDEXER_PASSWORD` (se aplica solo en el primer arranque). |
| Incidents / Responder reiniciándose | Falta `secrets/indexer/indexer_password` o tiene otro dueño: repetir el paso 6. |
| Botón de Logto da error al volver | El proxy no es HTTPS, o `base_redirect_url` no coincide con el dominio. |
| Usuario de Logto ve "Access not granted" | No tiene rol `tsoc-*` en Logto, o falta `ops/oidc/wazuh-rbac.sh`. |
| No llegan alertas a `triplesoc-alerts-*` | Falta `triplesoc-indexer/setup.sh` (paso 6) o el disco del indexer pasa del 90 %. |

## Qué nunca va en git

`deploy/.env`, `deploy/certs/`, `deploy/secrets/` y los archivos de `deploy/config/` sin `.example`
(están en `.gitignore`), además del `client_secret` de Logto, la URL de Teams y las claves de IA.
