"""Set de oro · paso 1: muestra estratificada de alertas reales (SOLO LEE el indexer).

Se ejecuta dentro del contenedor del Responder, que ya tiene el usuario de lectura del indexer:
  docker exec -i triplesoc-responder-<SID> python - < sample-alerts.py > /opt/triplesoc/golden/<fecha>/sample.jsonl
Toma hasta PER_RULE alertas por regla (todas si la regla tiene menos), con semilla fija para que la muestra
sea repetible, y añade la resolución humana del incidente si la tiene (Incidents → triage).
"""
import json
import os
import sys

sys.path.insert(0, "/app")
import responder as R
import tsoc_schema as TS

R.AUTH = R._auth()  # main() lo hace al arrancar el servicio; aquí no se llama a main()

PER_RULE = int(os.environ.get("PER_RULE", "20"))
SEED = int(os.environ.get("SEED", "20261020"))
F = TS.F

rules = R.req("POST", f"/{TS.ALERTS_INDEX}/_search", {"size": 0, "aggs": {"r": {"terms": {"field": F["rule_id"], "size": 1000}}}})
buckets = rules["aggregations"]["r"]["buckets"]

# Resolución humana: incidentes cerrados desde el dashboard (false_positive, resolved...).
human = {}
inc = R.req("POST", f"/{R.INCIDENTS_INDEX}/_search", {"size": 1000, "_source": ["resolution", "status", "sample_alert_ids"],
                                                     "query": {"exists": {"field": "resolution"}}}, ok404=True) or {}
for h in inc.get("hits", {}).get("hits", []):
    for aid in h["_source"].get("sample_alert_ids") or []:
        human[aid] = h["_source"].get("resolution")

n = 0
for b in buckets:
    res = R.req("POST", f"/{TS.ALERTS_INDEX}/_search", {
        "size": PER_RULE,
        "_source": TS.source("alert_id", "timestamp", "agent", "rule_id", "severity", "rule_description", "rule_groups",
                             "rule_mitre") + ["data.srcip", "data.usb.device"],
        "query": {"function_score": {"query": {"term": {F["rule_id"]: b["key"]}},
                                     "random_score": {"seed": SEED, "field": "_seq_no"}}}})
    for h in res["hits"]["hits"]:
        a = TS.normalize(h["_source"])
        rule = a.get("rule") or {}
        data = a.get("data") or {}
        out = {"alert_id": a.get("id"), "timestamp": a.get("timestamp"),
               "agent": {k: (a.get("agent") or {}).get(k) for k in ("id", "name")},
               "rule_id": str(rule.get("id")), "level": TS.severity(a), "desc": rule.get("description"),
               "groups": rule.get("groups") or [], "mitre": (rule.get("mitre") or {}).get("tactic") or [],
               "srcip": data.get("srcip"), "usb_device": (data.get("usb") or {}).get("device"),
               "rule_total": b["doc_count"], "human_resolution": human.get(a.get("id"))}
        print(json.dumps(out, ensure_ascii=False))
        n += 1
print(f"muestra: {n} alertas de {len(buckets)} reglas (máx. {PER_RULE} por regla)", file=sys.stderr)
