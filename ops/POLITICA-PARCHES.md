# Política de parches TripleSOC

Versión 1.0 · 20-10-2026 · Responsable: equipo TripleSOC (TripleCyber)

## 1. Alcance

Cubre las 7 imágenes del stack TripleSOC y las piezas que contienen:

| Capa | Imágenes | Quién publica el parche |
|---|---|---|
| Base Wazuh (oficial) | wazuh-indexer, wazuh-manager, wazuh-dashboard | Wazuh. TripleSOC reconstruye su capa encima. |
| Servicios propios | triplesoc-responder, triplesoc-incidents, triplesoc-rulesmith, webhook-receiver | TripleSOC, sobre `python:3.12-alpine`. |
| Agente en los equipos | Wazuh agent + scripts `triplesoc-endpoints` | Wazuh (agente) y TripleSOC (scripts). |

La versión 5.x de Wazuh queda fuera del ciclo automático hasta que exista su adaptador en la capa traductora (`schema/`).

## 2. Plazos (desde que se detecta la vulnerabilidad)

| Gravedad (CVSS / Trivy) | Plazo para corregir o mitigar | Ejemplos |
|---|---|---|
| **Crítica** (≥ 9.0), o cualquiera del catálogo KEV de CISA | **72 horas** | ejecución remota, bypass de autenticación |
| **Alta** (7.0 – 8.9) | **7 días** | escalada de privilegios, DoS remoto |
| **Media** (4.0 – 6.9) | **30 días** | fugas de información con condiciones |
| **Baja** (< 4.0) | siguiente versión programada | — |

"Corregir" significa que la imagen del stack ya no contiene el componente vulnerable. "Mitigar" significa que existe un control compensatorio documentado (sección 5), con fecha de revisión.

## 3. Cómo se detecta

1. **SBOM y vulnerabilidades, cada semana y tras cada cambio de imagen:** `ops/sbom.sh` (Syft + Trivy). El resultado queda en `/opt/triplesoc/sbom/<fecha>/RESUMEN.md`.
2. **Versiones nuevas de Wazuh:** el vigía de versiones del plan de actualización continua avisa por Teams.
3. **Avisos externos:** CISA KEV, avisos de seguridad de Wazuh y de Alpine/Python.

## 4. Cómo se aplica (siempre igual)

1. **Triage** (día 0): ¿el componente vulnerable se usa de verdad? ¿Está expuesto? ¿Aparece en KEV? Se anota en el registro (sección 6).
2. **Construir:** se reconstruye la imagen afectada con el `build.sh` de su carpeta.
   - Servicios propios: se sube la versión de la base o del paquete.
   - Capa Wazuh: se usa la versión de Wazuh corregida (`./build.sh 4.14.8`). Nuestra capa se vuelve a aplicar encima y el build falla si Wazuh movió algo.
3. **Probar:** `ops/recibir-version.sh probar 4.14.9` hace el respaldo, construye las candidatas y pasa el canario y el set de oro sin tocar el stack.
4. **Promover:** `ops/recibir-version.sh promover 4.14.9`. Repite las comprobaciones, promociona en el orden de Wazuh y verifica en vivo; si algo sale ROJO, vuelve solo a las etiquetas `<tag>-pre-<fecha>`.
5. **Nunca a mano:** ninguna versión de Wazuh entra por otro camino. Un cambio de motor OpenSearch o de versión mayor (5.x) se rechaza y se planifica aparte.
6. **Evidencia:** un nuevo `sbom.sh` que muestre la vulnerabilidad cerrada, y un commit en el repositorio.

## 5. Excepciones (cuando el parche no existe todavía)

Si la vulnerabilidad está en la capa oficial de Wazuh y Wazuh no ha publicado la corrección, TripleSOC no modifica sus binarios. En su lugar:

- se documenta un **control compensatorio**: no exponer el puerto o el servicio, restringir la red (NSG), desactivar la función afectada o filtrar en el proxy;
- se registra la **aceptación del riesgo**, con su justificación y una fecha de revisión de 30 días como máximo;
- se aplica el parche en cuanto Wazuh lo publique, con el plazo de la sección 2 contado desde ese momento.

## 6. Registro

Cada vulnerabilidad Crítica o Alta tiene una fila en `ops/registro-parches.md`:

| Fecha detección | CVE | Imagen / componente | Gravedad | Decisión (parche / mitigación / riesgo aceptado) | Fecha cierre | Evidencia |
|---|---|---|---|---|---|---|

## 7. Revisión

Esta política se revisa cada trimestre, y también cuando cambie la versión mayor de Wazuh.
