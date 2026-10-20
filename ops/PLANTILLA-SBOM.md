# Ficha SBOM TripleSOC · versión {{VERSION}} · {{FECHA}}

Ficha de transparencia que se entrega con cada versión de TripleSOC. Los datos salen de `ops/sbom.sh`: el apartado 2 se copia de `RESUMEN.md` y los archivos CycloneDX se adjuntan tal cual.

## 1. Versión entregada

| Imagen | Etiqueta | ID (sha256, 12) | Base oficial |
|---|---|---|---|
| triplesoc/wazuh-indexer | {{TAG}} | {{ID}} | wazuh/wazuh-indexer {{WAZUH}} |
| triplesoc/wazuh-manager | {{TAG}} | {{ID}} | wazuh/wazuh-manager {{WAZUH}} |
| triplesoc/wazuh-dashboard | {{TAG}} | {{ID}} | wazuh/wazuh-dashboard {{WAZUH}} |
| triplesoc/responder | {{TAG}} | {{ID}} | python:3.12-alpine |
| triplesoc/incidents | {{TAG}} | {{ID}} | python:3.12-alpine |
| triplesoc/rulesmith | {{TAG}} | {{ID}} | python:3.12-alpine |
| webhook-receiver | {{TAG}} | {{ID}} | python:3.12-alpine |

Contrato de la capa traductora: `{{CONTRATO}}` (adaptador `{{ADAPTADOR}}`).

## 2. Componentes y vulnerabilidades

| Imagen | Componentes | Críticas | Altas | Medias | Bajas |
|---|---:|---:|---:|---:|---:|
| … | … | … | … | … | … |

Herramientas: Syft {{SYFT}} (inventario CycloneDX) y Trivy {{TRIVY}} (vulnerabilidades), con base de datos del {{FECHA_DB}}.

## 3. Estado de las críticas y altas

Una fila por CVE crítico o alto, tomada de `ops/registro-parches.md`:

| CVE | Imagen / componente | Capa (oficial / propia) | Decisión | Plazo según política | Estado |
|---|---|---|---|---|---|

## 4. Licencias

- Dashboard e indexer: Apache-2.0. Manager, agente y plugins de Wazuh: GPL-2.0. Servicios TripleSOC: {{LICENCIA_PROPIA}}.
- Componentes con licencia GPL/AGPL/LGPL por imagen: ver `RESUMEN.md`, apartado "Licencias de copia fuerte".
- La marca Wazuh no aparece en la interfaz TripleSOC. Las imágenes base conservan sus avisos de licencia.

## 5. Adjuntos

- `<imagen>.cdx.json`: SBOM CycloneDX de cada imagen.
- `<imagen>.vulns.json`: informe de Trivy.
- `RESUMEN.md`: el resumen generado por `ops/sbom.sh`.

Política aplicada: `ops/POLITICA-PARCHES.md` (críticas en ≤ 72 h).
