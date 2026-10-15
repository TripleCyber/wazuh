# TripleSOC Rulesmith — fábrica de reglas con IA (v0.1)

La IA redacta reglas de detección para Wazuh. El servicio las valida y una persona las aprueba en el dashboard
(**AI Rules**). Ninguna regla se instala sin aprobación, y primero entra en modo silencioso.

## Cómo funciona

| Paso | Quién | Qué pasa |
|---|---|---|
| 1. Petición | Analista (pantalla AI Rules) o CISA KEV (cada 24 h) | Documento `requested` en `triplesoc-incidents-rules` |
| 2. Redacción | IA (misma clave y modelo que el Responder) | Devuelve una **especificación JSON**, nunca XML |
| 3. Validación | Servicio | Estructura y patrones; existencia del padre en el manager; ruido estimado con 30 días de histórico → `proposed` o `invalid` |
| 4. Revisión | Persona | Approve / Reject / “Revise” (le explica a la IA qué cambiar) |
| 5. Instalación silenciosa | Servicio (MODE=install) | Regenera `triplesoc_ai_rules.xml` → sube por la API → **valida la configuración** (si falla, restaura el archivo anterior) → reinicia el manager → pasa las líneas de prueba por **wazuh-logtest** |
| 6. Observación | Servicio | En silencio, el nivel es ≤ 11 (no avisa a Teams ni al webhook) y nunca baja del nivel del padre. Cuenta las coincidencias en 7 días |
| 7. Promoción o baja | Persona | Promote (solo si pasaron todas las pruebas) → nivel real. Disable → se quita del archivo |

**Barreras de seguridad:**
- La IA solo rellena campos acotados. El XML lo genera el servicio, escapando cada valor y con una lista cerrada de elementos.
- Los ids van en un rango propio (101000–101999) y en un archivo propio: no puede tocar reglas de Wazuh ni `triplesoc_rules.xml`.
- El usuario de API solo puede leer reglas, escribir **ese** archivo, validar, reiniciar y usar logtest.
- Hay un límite diario de redacciones (`MAX_DRAFTS_PER_DAY`) para no agotar la capa gratuita de la IA.

## Archivos

- `rulesmith.py`, `Dockerfile`, `build.sh`: el servicio (Python sin dependencias).
- Dashboard: `triplesoc-dashboard/overlay/triplesoc-rules-ui.js` (pantalla), entrada “AI Rules” en `triplesoc-nav.js`,
  estilos `tsocRul__*` en `triplesoc.css.tpl`, paso 4e en `apply-branding.sh`, tablero de ruta en `saved-objects/triplesoc-rules.js`.

## Despliegue en dev (por fases, cada una reversible)

### Fase A: solo redacta (MODE=propose; no toca Wazuh)
1. Respaldo: compose actual e imagen del dashboard (igual que en despliegues anteriores).
2. Copiar `triplesoc-rulesmith/` a `/opt/triplesoc/triplesoc-rulesmith` y ejecutar `./build.sh 0.1`.
3. Dashboard: copiar los 4 archivos tocados a `/opt/triplesoc/triplesoc-dashboard`, reconstruir con un tag de prueba y cambiar la imagen en el compose.
4. Crear el tablero de ruta: pegar `saved-objects/triplesoc-rules.js` en la consola del navegador (con la sesión iniciada).
5. Añadir al compose un bloque `triplesoc-rulesmith` copiado del de `triplesoc-responder`, con los mismos montajes del indexer y de `responder-secrets` (clave de la IA, solo lectura):
   ```yaml
   triplesoc-rulesmith:
     image: 'triplesoc/rulesmith:0.1'
     pull_policy: never
     restart: unless-stopped
     mem_limit: 192m
     environment:
       MODE: propose
       AI_PROVIDER: compatible
       AI_BASE_URL: 'https://api.groq.com/openai/v1'
       AI_MODEL: openai/gpt-oss-120b
       # mismos INDEXER_URL / INDEXER_USER / CA_FILE que el responder
     volumes:
       # mismos montajes que el responder: certificados, contraseña del indexer y responder-secrets
   ```
6. `docker compose -p $S up -d --no-deps triplesoc-rulesmith` y revisar los logs.

**Prueba:** en AI Rules, pedir “PowerShell launched by Word or Excel”. En menos de 1 minuto debe aparecer en *To review*, con el XML y las validaciones.

### Fase B: instalar lo aprobado (MODE=install)
Lo hace **la persona** en el dashboard (Security), con estos campos:
- Política `triplesoc_rulesmith_read`: acción `rules:read`, recurso `rule:file:*`.
- Política `triplesoc_rulesmith_write`: acciones `rules:update` y `rules:delete`, recurso `rule:file:triplesoc_ai_rules.xml`.
- Política `triplesoc_rulesmith_manager`: acciones `manager:read`, `manager:restart` y `logtest:run`, recurso `*:*:*`.
- Rol `triplesoc_rulesmith_svc` con las 3 políticas, y usuario `triplesoc_rulesmith`.
- Contraseña en `/opt/triplesoc/rulesmith-secrets/wazuh_api_password` (dueño 10001, modo 400), montada en `/run/triplesoc-rulesmith`.

Después: `MODE: install` en el compose y `up -d --no-deps triplesoc-rulesmith`.

**Prueba:** aprobar la regla de prueba. El manager se reinicia (~1 min), la regla queda en *Silent test* con el resultado de logtest, y en Threat Hunting aparece `rule.groups: triplesoc_ai_silent` cuando salta.

## Revertir
- **Servicio:** quitar el bloque del compose y `docker rm -f` el contenedor. El índice solo guarda propuestas.
- **Reglas instaladas:** Disable en el dashboard. A mano: `rm /var/ossec/etc/rules/triplesoc_ai_rules.xml` en el manager y reiniciarlo.
- **Dashboard:** volver a la imagen anterior (tag de respaldo).

## Pendiente (siguientes versiones)
- Fuentes: reglas **Sigma** (traducción asistida), **MITRE ATT&CK** (huecos de cobertura) y falsos positivos marcados en Incidents (excepciones).
- “Protección demostrada”: simular técnicas y medir el % de cobertura.
- Recarga de reglas sin reiniciar el manager, si la versión de Wazuh lo permite.
