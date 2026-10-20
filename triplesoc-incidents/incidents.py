#!/usr/bin/env python3
"""TripleSOC Incidents: correlación de alertas en incidentes.

Lee las alertas de triplesoc-alerts-* y agrupa en un mismo incidente las del mismo equipo
y la misma categoría que llegan con menos de WINDOW_MIN minutos de diferencia.
Escribe en su propio índice (triplesoc-incidents); NO modifica alertas ni nada de Wazuh.

Campos que gestiona este servicio: título, severidad, puntuación, contadores, reglas, MITRE,
primeras/últimas fechas. Los del triage (status, assignee, notes, acknowledged_at, resolved_at,
resolution) solo los escribe el dashboard; aquí únicamente se inicializan al crear el incidente.

Solo librería estándar de Python (sin dependencias que actualizar).
"""
import base64
import hashlib
import json
import math
import os
import ssl
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

import tsoc_schema as TS  # capa traductora: índice de alertas y campos de Wazuh

INDEXER_URL = os.environ.get("INDEXER_URL", "https://wazuh-indexer:9200").rstrip("/")
INDEXER_USER = os.environ.get("INDEXER_USER", "triplesoc_incidents")
PASSWORD_FILE = os.environ.get("INDEXER_PASSWORD_FILE", "/run/triplesoc/indexer_password")
CA_FILE = os.environ.get("CA_FILE", "/certs/root-ca.pem")
ALERTS_INDEX = TS.ALERTS_INDEX
INCIDENTS_INDEX = os.environ.get("INCIDENTS_INDEX", "triplesoc-incidents")
STATE_INDEX = os.environ.get("STATE_INDEX", "triplesoc-incidents-state")
MIN_LEVEL = int(os.environ.get("MIN_LEVEL", "5"))
WINDOW_MIN = int(os.environ.get("WINDOW_MIN", "30"))
INTERVAL_SEC = int(os.environ.get("INTERVAL_SEC", "30"))
BACKFILL_HOURS = int(os.environ.get("BACKFILL_HOURS", "168"))
SETTLE_SEC = int(os.environ.get("SETTLE_SEC", "60"))  # margen para alertas que se indexan con retraso
BATCH = int(os.environ.get("BATCH", "500"))
DRY_RUN = os.environ.get("DRY_RUN", "0") == "1"
HEARTBEAT = os.environ.get("HEARTBEAT_FILE", "/tmp/heartbeat")
OPEN_STATUSES = ("new", "investigating")

# Categoría por grupos de regla (la primera que coincide). Clave estable + título legible.
CATEGORIES = [
    ("unauthorized_device", {"triplesoc_unauthorized_device", "triplesoc_usb"}, "Unauthorized device connected"),
    ("integration_test", {"triplesoc_test"}, "TripleSOC integration test"),
    ("auth_failure", {"authentication_failed", "authentication_failures", "win_authentication_failed"}, "Authentication failures"),
    ("account_change", {"account_changed"}, "Account changes"),
    ("policy_change", {"policy_changed"}, "Security policy changes"),
    ("malware", {"rootcheck", "virustotal", "malware", "yara"}, "Malware / rootkit indicators"),
    ("vulnerability", {"vulnerability-detector"}, "Vulnerabilities detected"),
    ("web_attack", {"web", "attack", "sqlinjection", "xss"}, "Web attack attempts"),
    ("registry_integrity", {"syscheck_registry"}, "Registry integrity changes"),
    ("file_integrity", {"syscheck"}, "File integrity changes"),
    ("configuration", {"sca"}, "Configuration assessment failures"),
    ("agent_health", {"agent_flooding", "wazuh"}, "Agent health"),
    ("windows_security", {"windows_security"}, "Windows security events"),
    ("windows_system", {"windows_system", "windows_application", "system_error"}, "Windows system events"),
]
TACTIC_ORDER = ["Reconnaissance", "Resource Development", "Initial Access", "Execution", "Persistence",
                "Privilege Escalation", "Defense Evasion", "Credential Access", "Discovery", "Lateral Movement",
                "Collection", "Command and Control", "Exfiltration", "Impact"]

INCIDENTS_MAPPING = {
    "settings": {"number_of_shards": 1, "number_of_replicas": 0},
    "mappings": {"dynamic": True, "properties": {
        "incident_id": {"type": "keyword"}, "title": {"type": "text", "fields": {"keyword": {"type": "keyword", "ignore_above": 256}}},
        "category": {"type": "keyword"}, "status": {"type": "keyword"}, "severity": {"type": "keyword"},
        "severity_rank": {"type": "integer"}, "score": {"type": "integer"}, "resolution": {"type": "keyword"},
        "agent": {"properties": {"id": {"type": "keyword"}, "name": {"type": "keyword"}, "ip": {"type": "keyword"}}},
        "first_seen": {"type": "date"}, "last_seen": {"type": "date"}, "created_at": {"type": "date"},
        "updated_at": {"type": "date"}, "acknowledged_at": {"type": "date"}, "resolved_at": {"type": "date"},
        "alert_count": {"type": "integer"}, "max_level": {"type": "integer"}, "multi_stage": {"type": "boolean"},
        "assignee": {"type": "keyword"},
        "rules": {"properties": {"id": {"type": "keyword"}, "description": {"type": "keyword"}, "level": {"type": "integer"}, "count": {"type": "integer"}}},
        "mitre": {"properties": {"tactics": {"type": "keyword"}, "techniques": {"type": "keyword"}, "ids": {"type": "keyword"}}},
        "sample_alert_ids": {"type": "keyword"},
        "notes": {"properties": {"at": {"type": "date"}, "by": {"type": "keyword"}, "text": {"type": "text"}}},
    }},
}


def log(msg):
    print(f"[{datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}] {msg}", flush=True)


# ------------------------------------------------------------------ indexer
def _ctx():
    ctx = ssl.create_default_context(cafile=CA_FILE) if os.path.exists(CA_FILE) else ssl.create_default_context()
    if os.environ.get("TLS_VERIFY_HOSTNAME", "1") == "0":
        ctx.check_hostname = False
    return ctx


SSL_CTX = _ctx()


def _auth():
    with open(PASSWORD_FILE) as f:
        pwd = f.read().strip()
    return "Basic " + base64.b64encode(f"{INDEXER_USER}:{pwd}".encode()).decode()


AUTH = None


def req(method, path, body=None, ndjson=False, ok404=False):
    data = None
    headers = {"Authorization": AUTH}
    if body is not None:
        data = body.encode() if isinstance(body, str) else json.dumps(body).encode()
        headers["Content-Type"] = "application/x-ndjson" if ndjson else "application/json"
    r = urllib.request.Request(INDEXER_URL + path, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(r, context=SSL_CTX, timeout=30) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        if ok404 and e.code == 404:
            return None
        raise RuntimeError(f"{method} {path} -> {e.code}: {e.read()[:400]!r}")


def create_index(name, body):
    # Se crea directamente (permiso create_index); si ya existe, OpenSearch responde 400
    # resource_already_exists_exception. Así el usuario del servicio no necesita indices:admin/get.
    try:
        req("PUT", f"/{name}", body)
        log(f"índice {name} creado")
    except RuntimeError as e:
        if "resource_already_exists_exception" not in str(e):
            raise


def ensure_indices():
    if DRY_RUN:
        return
    create_index(INCIDENTS_INDEX, INCIDENTS_MAPPING)
    create_index(STATE_INDEX, {"settings": {"number_of_shards": 1, "number_of_replicas": 0},
                               "mappings": {"properties": {"cursor_json": {"type": "keyword", "index": False},
                                                           "updated_at": {"type": "date"}}}})


# El cursor ([timestamp en ms, id de alerta]) se guarda como texto JSON: una lista con tipos
# mezclados no se puede mapear en el índice.
def load_cursor():
    doc = req("GET", f"/{STATE_INDEX}/_doc/cursor", ok404=True)
    raw = doc["_source"].get("cursor_json") if doc and doc.get("found") else None
    return json.loads(raw) if raw else None


def save_cursor(cursor):
    if not DRY_RUN:
        req("PUT", f"/{STATE_INDEX}/_doc/cursor", {"cursor_json": json.dumps(cursor), "updated_at": now_iso()})


def load_open_incidents():
    res = req("POST", f"/{INCIDENTS_INDEX}/_search", {
        "size": 2000, "query": {"terms": {"status": list(OPEN_STATUSES)}},
        "sort": [{"last_seen": "desc"}]}, ok404=True)
    out = {}
    for h in (res or {}).get("hits", {}).get("hits", []):
        s = h["_source"]
        key = (s["agent"]["id"], s["category"])
        if key not in out:  # el más reciente por clave
            out[key] = s
    return out


# ------------------------------------------------------------------ correlación
def now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def parse_ts(s):
    s = s.replace("Z", "+00:00")
    if len(s) > 5 and s[-5] in "+-" and s[-3] != ":":
        s = s[:-2] + ":" + s[-2:]  # +0000 -> +00:00
    return datetime.fromisoformat(s).astimezone(timezone.utc)


def iso(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def categorize(groups):
    gs = set(groups or [])
    for key, match, title in CATEGORIES:
        if gs & match:
            return key, title
    g = next((x for x in (groups or []) if x not in ("ossec", "local")), "other")
    return g, g.replace("_", " ").capitalize() + " events"


def severity_of(max_level, count, tactics):
    rank = 4 if max_level >= 12 else 3 if max_level >= 10 else 2 if max_level >= 7 else 1
    if count >= 100 and rank < 2:  # ráfaga sostenida de eventos menores
        rank = 2
    if len(tactics) >= 3 and rank < 4:  # varias fases de ataque en el mismo incidente
        rank += 1
    return rank, {4: "critical", 3: "high", 2: "medium", 1: "low"}[rank]


def score_of(max_level, count, tactics):
    s = min(75, max_level * 5) + min(15, int(math.log2(max(1, count)) * 2)) + min(10, len(tactics) * 3)
    return max(1, min(100, s))


def new_incident(alert, ts, cat_key, cat_title):
    agent = alert.get("agent", {})
    raw = f"{agent.get('id')}|{cat_key}|{alert.get('id')}"
    iid = "TSOC-" + hashlib.sha1(raw.encode()).hexdigest()[:8].upper()
    return {
        "incident_id": iid, "category": cat_key, "category_label": cat_title,
        "agent": {"id": agent.get("id"), "name": agent.get("name"), "ip": agent.get("ip")},
        "first_seen": iso(ts), "last_seen": iso(ts), "alert_count": 0, "max_level": 0,
        "rules": [], "mitre": {"tactics": [], "techniques": [], "ids": []}, "sample_alert_ids": [],
        # triage (lo gestiona el dashboard)
        "status": "new", "assignee": None, "notes": [], "acknowledged_at": None, "resolved_at": None,
        "resolution": None, "created_at": now_iso(), "_new": True,
    }


def merge(inc, alert, ts):
    rule = alert.get("rule", {})
    lvl = TS.severity(alert)
    inc["alert_count"] += 1
    inc["max_level"] = max(inc["max_level"], lvl)
    inc["last_seen"] = iso(max(ts, parse_ts(inc["last_seen"])))
    inc["first_seen"] = iso(min(ts, parse_ts(inc["first_seen"])))
    rules = {r["id"]: r for r in inc["rules"]}
    r = rules.setdefault(str(rule.get("id")), {"id": str(rule.get("id")), "description": rule.get("description"), "level": lvl, "count": 0})
    r["count"] += 1
    inc["rules"] = sorted(rules.values(), key=lambda x: (-x["level"], -x["count"]))[:15]
    m = rule.get("mitre") or {}
    for k_src, k_dst in (("tactic", "tactics"), ("technique", "techniques"), ("id", "ids")):
        cur = inc["mitre"][k_dst]
        for v in m.get(k_src) or []:
            if v not in cur:
                cur.append(v)
    inc["mitre"]["tactics"].sort(key=lambda t: TACTIC_ORDER.index(t) if t in TACTIC_ORDER else 99)
    ids = inc["sample_alert_ids"]
    if alert.get("id") and alert["id"] not in ids:
        ids.append(alert["id"])
        del ids[:-25]
    rank, sev = severity_of(inc["max_level"], inc["alert_count"], inc["mitre"]["tactics"])
    inc["severity"], inc["severity_rank"] = sev, rank
    inc["score"] = score_of(inc["max_level"], inc["alert_count"], inc["mitre"]["tactics"])
    inc["multi_stage"] = len(inc["mitre"]["tactics"]) >= 3
    top = inc["rules"][0]["description"] if inc["rules"] else inc["category_label"]
    name = inc["agent"].get("name") or inc["agent"].get("id")
    inc["title"] = f"{inc['category_label']} on {name}" if inc["alert_count"] > 1 else f"{top} on {name}"
    inc["_dirty"] = True


def fetch_alerts(cursor, until_ms):
    since = cursor[0] if cursor else int((time.time() - BACKFILL_HOURS * 3600) * 1000)
    body = {
        "size": BATCH, "sort": [{TS.F["timestamp"]: "asc"}, {TS.F["alert_id"]: "asc"}],
        "_source": TS.source("alert_id", "timestamp", "agent", "rule_id", "severity", "rule_description", "rule_groups", "rule_mitre"),
        "query": {"bool": {"filter": [
            TS.sev_gte(MIN_LEVEL),
            {"range": {TS.F["timestamp"]: {"gte": since, "lte": until_ms, "format": "epoch_millis"}}},
        ]}},
    }
    if cursor:
        body["search_after"] = cursor
    return req("POST", f"/{ALERTS_INDEX}/_search", body)["hits"]["hits"]


def flush(dirty):
    if not dirty:
        return
    lines = []
    for inc in dirty:
        is_new = inc.pop("_new", False)
        inc.pop("_dirty", None)
        inc["updated_at"] = now_iso()
        if is_new:
            lines.append(json.dumps({"create": {"_index": INCIDENTS_INDEX, "_id": inc["incident_id"]}}))
            lines.append(json.dumps(inc))
        else:  # solo campos de correlación: no pisa el triage hecho desde el dashboard
            doc = {k: inc[k] for k in ("title", "severity", "severity_rank", "score", "multi_stage", "last_seen",
                                       "first_seen", "alert_count", "max_level", "rules", "mitre",
                                       "sample_alert_ids", "updated_at")}
            lines.append(json.dumps({"update": {"_index": INCIDENTS_INDEX, "_id": inc["incident_id"]}}))
            lines.append(json.dumps({"doc": doc}))
    if DRY_RUN:
        return
    res = req("POST", "/_bulk?refresh=true", "\n".join(lines) + "\n", ndjson=True)
    if res.get("errors"):
        errs = [i for i in res["items"] if list(i.values())[0].get("error")]
        log(f"AVISO: {len(errs)} errores en bulk, p. ej. {json.dumps(errs[0])[:300]}")


def cycle(state):
    cursor = state["cursor"]
    # Se recarga en cada ciclo: así un incidente resuelto desde el dashboard ya no absorbe alertas nuevas.
    open_by_key = load_open_incidents()
    state["open"] = open_by_key
    until_ms = int((time.time() - SETTLE_SEC) * 1000)
    window = timedelta(minutes=WINDOW_MIN)
    processed = created = 0
    touched = {}
    while True:
        hits = fetch_alerts(cursor, until_ms)
        if not hits:
            break
        for h in hits:
            a = TS.normalize(h["_source"])
            ts = parse_ts(a["timestamp"])
            cat_key, cat_title = categorize(a.get("rule", {}).get("groups"))
            key = (a.get("agent", {}).get("id"), cat_key)
            inc = open_by_key.get(key)
            if inc is None or ts - parse_ts(inc["last_seen"]) > window:
                inc = new_incident(a, ts, cat_key, cat_title)
                open_by_key[key] = inc
                created += 1
            merge(inc, a, ts)
            touched[inc["incident_id"]] = inc
            processed += 1
        cursor = hits[-1]["sort"]
        flush([i for i in touched.values() if i.get("_dirty")])
        save_cursor(cursor)
        if len(hits) < BATCH:
            break
    state["cursor"] = cursor
    if processed:
        log(f"{processed} alertas correlacionadas -> {len(touched)} incidentes tocados ({created} nuevos)")
    return touched


def main():
    global AUTH
    AUTH = _auth()
    log(f"TripleSOC Incidents: {ALERTS_INDEX} -> {INCIDENTS_INDEX} (nivel>={MIN_LEVEL}, ventana {WINDOW_MIN} min"
        f"{', DRY-RUN' if DRY_RUN else ''})")
    while True:
        try:
            ensure_indices()
            break
        except Exception as e:  # el indexer puede tardar en arrancar
            log(f"esperando al indexer: {e}")
            time.sleep(15)
    state = {"cursor": None if DRY_RUN else load_cursor(), "open": {}}
    if state["cursor"] is None:
        log(f"sin cursor: se procesan las últimas {BACKFILL_HOURS} h")
    while True:
        try:
            touched = cycle(state)
            if DRY_RUN:
                incs = sorted(state["open"].values(), key=lambda i: i["first_seen"])
                log(f"(dry-run) {len(incs)} incidentes en total")
                for i in incs[-40:]:
                    log(f"  {i['incident_id']} {i['severity']:8} {i['score']:3} {i['alert_count']:5} "
                        f"{i['first_seen'][:16]}..{i['last_seen'][11:16]} {i['title']} {i['mitre']['tactics']}")
                return
            with open(HEARTBEAT, "w") as f:
                f.write(now_iso())
        except Exception as e:
            log(f"ERROR en el ciclo (se reintenta): {e}")
        time.sleep(INTERVAL_SEC)


if __name__ == "__main__":
    sys.exit(main())
