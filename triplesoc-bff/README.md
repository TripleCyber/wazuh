# triplesoc-bff · prototipo (documento enjambre, punto 4)

API propia de TripleSOC entre el frontend y el motor. El frontend nunca ve Wazuh: recibe el modelo TripleSOC (`severity.band`, `detection`, `endpoint`), y todas las consultas pasan por la capa traductora (`schema/`). Es de solo lectura y se autentica con token Bearer; `/api/v1/health` no pide token.

| Endpoint | Devuelve |
|---|---|
| `GET /api/v1/health` | Estado, versión, contrato y adaptador |
| `GET /api/v1/summary?window=24h` | Alertas, críticas, altas, equipos e incidentes abiertos por gravedad |
| `GET /api/v1/alerts?severity=critical\|high\|low&window=24h&limit=50` | Alertas en el modelo TripleSOC |
| `GET /api/v1/incidents?status=new&limit=50` | Incidentes de triplesoc-incidents |
| `GET /api/v1/responses?limit=20` | Decisiones del Responder (acción, riesgo, motor, quién decidió) |

Prueba en el servidor (sin publicar puertos; usa el usuario de lectura de Incidents):
```bash
S=yf8u7icjiq4vdhetmea7rmfr; mkdir -p /opt/triplesoc/triplesoc-bff/secret && chmod 700 /opt/triplesoc/triplesoc-bff/secret
[ -f /opt/triplesoc/triplesoc-bff/secret/token ] || (umask 077; head -c 32 /dev/urandom | base64 | tr -d '/+=' > /opt/triplesoc/triplesoc-bff/secret/token)
chown -R 10001 /opt/triplesoc/triplesoc-bff/secret
docker run -d --name triplesoc-bff-proto --network $S --memory 128m \
  -v /opt/triplesoc/triplesoc-incidents/secret:/run/triplesoc:ro -v /data/coolify/services/$S/certs:/certs:ro \
  -v /opt/triplesoc/triplesoc-bff/secret:/run/triplesoc-bff:ro triplesoc/bff:0.3
```
Para producción falta decidir: publicarlo con Traefik (dominio y lista de IP), un token por cliente o SSO, y añadirlo al compose de Coolify.
