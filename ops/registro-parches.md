# Registro de parches TripleSOC

Una fila por vulnerabilidad Crítica o Alta (ver `POLITICA-PARCHES.md`). La fuente es `/opt/triplesoc/sbom/ultimo/RESUMEN.md`.

| Fecha detección | CVE | Imagen / componente | Gravedad | Decisión (parche / mitigación / riesgo aceptado) | Fecha cierre | Evidencia |
|---|---|---|---|---|---|---|
| 16-10-2026 | CVE-2025-7783 | wazuh-dashboard 4.14.7 · form-data 3.0.1 (corr. 3.0.4) | Crítica | Parche disponible en 4.14.9 (jsdom/form-data). Aplicar con el canario cuando haya disco (ver nota) | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-106445 | wazuh-dashboard 4.14.7 · handlebars 4.7.7 (corr. 4.7.10) | Crítica | Propuesta: mitigación parcial (dashboard tras login). Recomendado: lista de IP permitidas en Traefik. Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-106446 | wazuh-dashboard 4.14.7 · handlebars 4.7.7 (corr. 4.7.10) | Crítica | Propuesta: mitigación parcial (dashboard tras login). Recomendado: lista de IP permitidas en Traefik. Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-33937 | wazuh-dashboard 4.14.7 · handlebars 4.7.7 (corr. 4.7.9) | Crítica | Propuesta: mitigación parcial (dashboard tras login). Recomendado: lista de IP permitidas en Traefik. Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-31938 | wazuh-dashboard 4.14.7 · jspdf 4.2.0 (corr. 4.2.1) | Crítica | Propuesta: mitigación parcial (dashboard tras login). Recomendado: lista de IP permitidas en Traefik. Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-59873 | wazuh-dashboard 4.14.7 · tar 7.5.10 (corr. 7.5.19) | Crítica | Propuesta: mitigación parcial (dashboard tras login). Recomendado: lista de IP permitidas en Traefik. Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-85061 | wazuh-dashboard 4.14.7 · maplibre-gl 2.4.0 (corr. 6.4.1) | Crítica | Propuesta: mitigación parcial (dashboard tras login). Recomendado: lista de IP permitidas en Traefik. Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-90711 | wazuh-dashboard 4.14.7 · proxy-addr 2.0.7 (corr. 2.0.8) | Crítica | Propuesta: mitigación parcial (dashboard tras login). Recomendado: lista de IP permitidas en Traefik. Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2022-23806, CVE-2023-24538, CVE-2023-24540, CVE-2024-24790, CVE-2025-68121 | wazuh-manager 4.14.7 · Go stdlib 1.14.12 | Crítica | Propuesta: mitigado, no expuesto (lo usa Filebeat 7.10.2, que no escucha ningún puerto). Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-33186 | wazuh-manager 4.14.7 · grpc v1.29.1 (corr. 1.79.3) | Crítica | Propuesta: mitigado, no expuesto (lo usa Filebeat 7.10.2, que no escucha ningún puerto). Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-102268 | wazuh-manager 4.14.7 · pyjwt 2.13.0 (corr. 2.14.0) | Crítica | Propuesta: mitigado, no expuesto (API 55000 solo interna). Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-63374 | wazuh-manager 4.14.7 · anyio 4.1.0 (corr. 4.14.2) | Crítica | Propuesta: mitigado, no expuesto (API 55000 solo interna). Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2025-14813 | wazuh-indexer 4.14.7 · bouncycastle bcprov 1.78.1 / 1.82 (corr. 1.84) | Crítica | Propuesta: mitigado, no expuesto (9200 solo en la red interna del stack). Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-8763 | wazuh-indexer 4.14.7 · bouncycastle bc-fips 2.1.2 / bcprov (corr. 2.1.3 / 1.85) | Crítica | Propuesta: mitigado, no expuesto (9200 solo en la red interna del stack). Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |
| 16-10-2026 | CVE-2026-75595 | wazuh-indexer 4.14.7 · netty-handler 4.1.131 (corr. 4.1.137) | Crítica | Propuesta: mitigado, no expuesto (9200 solo en la red interna del stack). Sin parche upstream; revisar 19-11 | | sbom 20261016-1320 |

Servicios propios (responder, incidents, rulesmith, receptor): 0 críticas y 0 altas en el SBOM del 16-10.
El plazo de 72 h cuenta desde la adopción de la política (20-10-2026).

### Triage del 20-10-2026 (analista)

- Exposición comprobada en el servidor: solo se publican 1514/1515 (agentes, con NSG limitado) y el dashboard (443 vía Traefik). El indexer (9200) y la API del manager (55000) no salen de la red interna del stack.
- Wazuh 4.14.9 (16-10) solo corrige `form-data`, según sus notas de versión. Go 1.14 y grpc vienen de Filebeat 7.10.2, que Wazuh sigue empaquetando.
- **Bloqueo para aplicar 4.14.9:** el disco del servidor (61 GB) está al 83 %. Bajar las tres imágenes nuevas lo lleva cerca del 90 %, y con el 95 % el indexer pone los índices en solo lectura. Hay que ampliar el disco (recomendado 128 GB) antes de cualquier actualización de versión.
- Pendiente de dirección: aceptar formalmente los riesgos propuestos (columna Decisión) o pedir el control compensatorio del dashboard (lista de IP en Traefik; requiere IP fija o VPN, porque la IP de la oficina cambia).
