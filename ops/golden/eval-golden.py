"""Set de oro · paso 2: etiqueta la muestra y mide el pipeline de decisión de TripleSOC (documento enjambre 5.4).

Modo tabla fija (sin red, sin IA; repetible):
  docker run --rm --network none -v /opt/triplesoc/src:/src:ro -v /opt/triplesoc/golden/<fecha>:/g \
    triplesoc/responder:<tag> python /src/ops/golden/eval-golden.py /g
Modo IA (la IA real del Responder, una llamada por incidente alto o crítico): se ejecuta dentro del
contenedor del Responder con AI=1 (ver ops/golden/README.md).

Por cada alerta construye el incidente con el código real de Incidents (categoría, gravedad, puntuación,
MITRE) y pide la decisión al código real del Responder (decide + policy, con guardarraíles). Las consultas
al indexer y al endpoint se sustituyen por los datos de la propia alerta, así que la prueba no toca nada.
Escribe golden-set.jsonl (muestra etiquetada) y report-<modo>.md / .json en la carpeta indicada.
"""
import json
import os
import sys
import time
from datetime import datetime, timezone

SRC = os.environ.get("TSOC_SRC", "/src")
sys.path.insert(0, "/app")
sys.path.insert(0, os.path.join(SRC, "triplesoc-incidents"))
import incidents as I
import responder as R

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
USE_AI = os.environ.get("AI") == "1"
AI_PAUSE = float(os.environ.get("AI_PAUSE", "2.5"))  # el plan gratuito limita peticiones por minuto
HERE = os.path.join(SRC, "ops", "golden")
LABELS = json.load(open(os.path.join(HERE, "labels.json"), encoding="utf-8"))
SYNTH = json.load(open(os.path.join(HERE, "synthetic.json"), encoding="utf-8"))
CLASSES = ("contain", "review", "ignore")


def label(a):
    r = LABELS["rules"].get(a["rule_id"])
    if r:
        return r["verdict"], r["expected"], r["why"], "rule"
    for d in LABELS["defaults"]:
        if ("if_group" in d and d["if_group"] in a["groups"]) or ("if_level_lt" in d and a["level"] < d["if_level_lt"]):
            return d["verdict"], d["expected"], d["why"], "default"
    return None, None, None, None  # nivel 12+ sin etiqueta explícita: el analista debe etiquetarla


# ---- el entorno del Responder se sustituye por los datos de la alerta (nada sale del contenedor)
CUR = {}
R.log = lambda msg: None
R.phone_waiting = lambda *_: False
R.input_device_seen = lambda *_: False
R.usb_already_blocked = lambda *_: False
R.input_device_alert = lambda inc: bool(R.INPUT_DEVICE_RE.search(str(CUR.get("usb_device") or "")))
R.source_ip = lambda inc: CUR.get("srcip")
I.now_iso = lambda: "2026-10-20T00:00:00Z"
if not USE_AI:
    R.decide_ai = lambda inc: None


def run(a):
    CUR.clear()
    CUR.update(a)
    ts = I.parse_ts(a["timestamp"]) if a.get("timestamp") else datetime.now(timezone.utc)
    doc = {"id": a.get("alert_id") or a.get("sid"), "timestamp": a.get("timestamp"), "agent": a.get("agent") or {"id": "001", "name": "lab"},
           "rule": {"id": a["rule_id"], "level": a["level"], "description": a["desc"], "groups": a["groups"],
                    "mitre": {"tactic": a.get("mitre") or []}}}
    cat, title = I.categorize(a["groups"])
    inc = I.new_incident(doc, ts, cat, title)
    I.merge(inc, doc, ts)
    if inc["severity_rank"] < R.MIN_RANK:  # el Responder solo mira incidentes altos y críticos
        return "ignore", {"category": cat, "severity": inc["severity"], "action": None, "engine": "-", "decision": "-"}
    rec = R.recommend(inc)
    if USE_AI and not rec["engine"].endswith("ai-guard"):
        time.sleep(AI_PAUSE)
    pred = "review" if rec["action"] == "manual_review" else "contain"
    return pred, {"category": cat, "severity": inc["severity"], "action": rec["action"], "engine": rec["engine"],
                  "decision": rec["decision"]}


rows, unlabeled = [], []
sample = [json.loads(l) for l in open(os.path.join(OUT, "sample.jsonl"), encoding="utf-8") if l.strip()]
for a in sample + [dict(s, origin="synthetic") for s in SYNTH]:
    a.setdefault("origin", "real")
    if a["origin"] == "synthetic":
        verdict, expected, why, src = a["verdict"], a["expected"], a["why"], "synthetic"
    else:
        verdict, expected, why, src = label(a)
    if not expected:
        unlabeled.append(a)
        continue
    pred, info = run(a)
    rows.append(dict(a, verdict=verdict, expected=expected, why=why, label_source=src, reviewed_by=None,
                     predicted=pred, ok=pred == expected, **info))

mode = "ia" if USE_AI else "tabla"
with open(os.path.join(OUT, "golden-set.jsonl"), "w", encoding="utf-8") as f:
    for r in rows:
        f.write(json.dumps({k: r.get(k) for k in ("origin", "alert_id", "sid", "timestamp", "agent", "rule_id", "level", "desc",
                                                  "groups", "verdict", "expected", "why", "label_source", "reviewed_by",
                                                  "human_resolution")}, ensure_ascii=False) + "\n")

# ---- métricas
cm = {e: {p: 0 for p in CLASSES} for e in CLASSES}
for r in rows:
    cm[r["expected"]][r["predicted"]] += 1
pos = [r for r in rows if r["verdict"] == "positive"]
ben = [r for r in rows if r["verdict"] in ("benign", "finding", "test")]
must_contain = [r for r in rows if r["expected"] == "contain"]
caught = sum(1 for r in must_contain if r["predicted"] == "contain")
over = sum(1 for r in ben if r["predicted"] == "contain")
guard = [r for r in rows if r["rule_id"] in R.PROMPT_INJECTION_RULES or "ignore all previous" in str(r.get("desc")).lower()]
guard_ok = sum(1 for r in guard if "ai-guard" in str(r.get("engine")))
fails = [r for r in rows if not r["ok"]]
summary = {
    "mode": mode, "engine_model": R.AI_MODEL if USE_AI else "playbook-v0",
    "total": len(rows), "real": sum(r["origin"] == "real" for r in rows), "synthetic": sum(r["origin"] == "synthetic" for r in rows),
    "accuracy": round(sum(r["ok"] for r in rows) / max(1, len(rows)), 4),
    "containment_recall": round(caught / max(1, len(must_contain)), 4), "must_contain": len(must_contain),
    "benign_escalated": over, "benign_total": len(ben), "positives": len(pos),
    "ai_guard": f"{guard_ok}/{len(guard)}", "unlabeled": len(unlabeled), "confusion": cm,
}
json.dump({"summary": summary, "fails": [{k: r.get(k) for k in ("origin", "alert_id", "sid", "rule_id", "level", "desc",
                                                                 "expected", "predicted", "action", "engine", "category")} for r in fails]},
          open(os.path.join(OUT, f"report-{mode}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

L = [f"# Set de oro TripleSOC · modo {mode} · {datetime.now(timezone.utc):%Y-%m-%d %H:%M} UTC", "",
     f"Alertas evaluadas: **{summary['total']}** ({summary['real']} reales + {summary['synthetic']} sintéticas). "
     f"Sin etiqueta (nivel 12+ sin regla en labels.json): {summary['unlabeled']}.", "",
     "| Métrica | Valor |", "|---|---|",
     f"| Acierto global (acción esperada = acción del pipeline) | {summary['accuracy']:.1%} |",
     f"| Recall de contención (debía contenerse y se propuso contener) | {caught}/{len(must_contain)} = {summary['containment_recall']:.1%} |",
     f"| Benignas escaladas a contención (falsas alarmas graves) | {over}/{len(ben)} |",
     f"| Inyecciones de prompt resueltas sin consultar a la IA | {summary['ai_guard']} |", "",
     "Matriz de confusión (filas = esperado, columnas = pipeline):", "",
     "| esperado \\ pipeline | contain | review | ignore |", "|---|---:|---:|---:|"]
L += [f"| {e} | {cm[e]['contain']} | {cm[e]['review']} | {cm[e]['ignore']} |" for e in CLASSES]
L += ["", f"## Fallos ({len(fails)})", ""]
L += [f"- `{r.get('sid') or r['rule_id']}` nivel {r['level']} · {str(r['desc'])[:70]} → esperado **{r['expected']}**, "
      f"pipeline **{r['predicted']}** ({r.get('action') or '-'}, {r.get('engine')}, categoría {r.get('category')})" for r in fails[:60]]
if unlabeled:
    L += ["", "## Reglas de nivel 12+ sin etiqueta", ""] + sorted({f"- {a['rule_id']} · {a['desc']}" for a in unlabeled})
open(os.path.join(OUT, f"report-{mode}.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")
print(json.dumps(summary, ensure_ascii=False))
