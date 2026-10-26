# Set de oro TripleSOC (documento enjambre, sección 5.4)

Mide con datos reales cuánto acierta el pipeline de decisión (Incidents → Responder, con guardarraíles y, en modo IA, la IA real) antes de dar más autonomía a la IA.

| Archivo | Qué es |
|---|---|
| `labels.json` | Etiquetas del analista, por regla y en el contexto del entorno: `verdict` (positive / benign / finding / test) y `expected` (contain / review / ignore). |
| `synthetic.json` | 16 casos de ataque que el entorno dev aún no ha visto (malware, SQLi, fuerza bruta, BadUSB, inyección dentro de un nombre de archivo...). |
| `sample-alerts.py` | Paso 1: muestra estratificada de alertas reales (hasta 20 por regla, semilla fija). Solo lee el indexer. |
| `eval-golden.py` | Paso 2: etiqueta la muestra, pasa cada alerta por el código real de Incidents y Responder y escribe `golden-set.jsonl` + `report-<modo>.md/json`. |

```bash
D=/opt/triplesoc/golden/$(date +%Y%m%d); mkdir -p $D; S=yf8u7icjiq4vdhetmea7rmfr
docker exec -i triplesoc-responder-$S python - < /opt/triplesoc/src/ops/golden/sample-alerts.py > $D/sample.jsonl
# modo tabla fija: sin red ni IA
docker run --rm --network none -v /opt/triplesoc/src:/src:ro -v $D:/g triplesoc/responder:0.16 python /src/ops/golden/eval-golden.py /g
# modo IA: una llamada por incidente alto o crítico (pocas decenas)
docker exec triplesoc-responder-$S python -c "import os; os.makedirs('/tmp/g/src', exist_ok=True)" && docker cp /opt/triplesoc/src/. triplesoc-responder-$S:/tmp/g/src \
  && docker cp $D/sample.jsonl triplesoc-responder-$S:/tmp/g/ \
  && docker exec -e AI=1 -e TSOC_SRC=/tmp/g/src triplesoc-responder-$S python /tmp/g/src/ops/golden/eval-golden.py /tmp/g \
  && docker cp triplesoc-responder-$S:/tmp/g/report-ia.md $D/ && docker cp triplesoc-responder-$S:/tmp/g/report-ia.json $D/
```

Métricas: acierto global, **recall de contención** (lo que debía contenerse y se propuso contener), **benignas escaladas** a contención y las inyecciones resueltas sin consultar a la IA.

Revisión humana: un analista revisa por muestreo `golden-set.jsonl`, anota `reviewed_by` y corrige `labels.json` si discrepa. Las etiquetas por regla valen para este entorno; un cliente nuevo necesita las suyas.
