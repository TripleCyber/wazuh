#!/usr/bin/env python3
"""TripleSOC BFF (backend-for-frontend), prototipo · documento enjambre, punto 4 de los 30 días.

API propia de TripleSOC para un frontend futuro (consola web, app, integraciones de clientes).
El frontend nunca habla con Wazuh: pide aquí y recibe el modelo TripleSOC, sin campos de Wazuh
(nada de rule.level, agent.name ni nombres de índice). Las consultas pasan por la capa traductora
(tsoc_schema): cuando cambie Wazuh, la API y sus clientes siguen igual.

Solo lectura. Autenticación con token Bearer (archivo TOKEN_FILE). Sin dependencias externas.
  GET /api/v1/health                       estado, contrato y adaptador
  GET /api/v1/summary?window=24h           alertas, críticas, equipos e incidentes abiertos
  GET /api/v1/alerts?severity=critical&window=24h&limit=50
  GET /api/v1/incidents?status=new&limit=50
  GET /api/v1/responses?limit=20           decisiones del Responder (qué propuso, quién decidió)
"""
import base64
import hmac
import json
import os
import re
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tsoc_schema as TS

VERSION = "0.1"
INDEXER_URL = os.environ.get("INDEXER_URL", "https://wazuh-indexer:9200").rstrip("/")
INDEXER_USER = os.environ.get("INDEXER_USER", "triplesoc_incidents")
PASSWORD_FILE = os.environ.get("INDEXER_PASSWORD_FILE", "/run/triplesoc/indexer_password")
CA_FILE = os.environ.get("CA_FILE", "/certs/root-ca.pem")
TOKEN_FILE = os.environ.get("TOKEN_FILE", "/run/triplesoc-bff/token")
INCIDENTS_INDEX = os.environ.get("INCIDENTS_INDEX", "triplesoc-incidents")
RESPONSES_INDEX = os.environ.get("RESPONSES_INDEX", "triplesoc-incidents-responses")
PORT = int(os.environ.get("PORT", "8090"))
MAX_LIMIT = 200
F = TS.F
BANDS = {"critical": (TS.CRITICAL, None), "high": (TS.HIGH, TS.CRITICAL), "low": (None, TS.HIGH)}
WINDOW_RE = re.compile(r"^\d{1,3}[mhd]$")
VENDOR = re.compile(r"wazuh|ossec", re.I)  # el modelo TripleSOC no nombra al proveedor del motor

SSL_CTX = ssl.create_default_context(cafile=CA_FILE) if os.path.exists(CA_FILE) else ssl.create_default_context()


def _auth_header():
    with open(PASSWORD_FILE, encoding="utf-8") as f:
        return "Basic " + base64.b64encode(f"{INDEXER_USER}:{f.read().strip()}".encode()).decode()


def _token():
    with open(TOKEN_FILE, encoding="utf-8") as f:
        t = f.read().strip()
    if len(t) < 24:
        raise SystemExit("TOKEN_FILE debe contener un token de al menos 24 caracteres")
    return t


AUTH = None
TOKEN = None


def search(index, body):
    r = urllib.request.Request(f"{INDEXER_URL}/{index}/_search", data=json.dumps(body).encode(), method="POST",
                               headers={"Authorization": AUTH, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r, context=SSL_CTX, timeout=20) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return {"hits": {"hits": [], "total": {"value": 0}}, "aggregations": {}}
        raise


# ------------------------------------------------------------------ modelo TripleSOC (sin campos de Wazuh)
def clean(s):
    return VENDOR.sub("TripleSOC", str(s or ""))


def alert_out(doc):
    a = TS.normalize(doc)
    rule, agent = a.get("rule") or {}, a.get("agent") or {}
    lvl = TS.severity(a)
    mitre = rule.get("mitre") or {}
    return {"id": a.get("id"), "time": a.get("timestamp"),
            "severity": {"band": TS.band(lvl), "score": lvl},
            "detection": {"id": str(rule.get("id")), "title": clean(rule.get("description")),
                          "tactics": mitre.get("tactic") or [], "techniques": mitre.get("id") or []},
            "endpoint": {"id": agent.get("id"), "name": clean(agent.get("name"))}}


def incident_out(i):
    ag = i.get("agent") or {}
    return {"id": i.get("incident_id"), "title": clean(i.get("title")), "category": i.get("category"),
            "severity": i.get("severity"), "score": i.get("score"), "status": i.get("status"),
            "assignee": i.get("assignee"), "alerts": i.get("alert_count"), "first_seen": i.get("first_seen"),
            "last_seen": i.get("last_seen"), "endpoint": {"id": ag.get("id"), "name": clean(ag.get("name"))},
            "tactics": (i.get("mitre") or {}).get("tactics") or []}


def response_out(r):
    ag = r.get("agent") or {}
    return {"incident": r.get("incident_id"), "action": r.get("action"), "action_label": r.get("action_label"),
            "risk": r.get("risk"), "decision": r.get("decision"), "status": r.get("status"),
            "engine": r.get("engine"), "confidence": r.get("confidence"), "reason": clean(r.get("reason")),
            "endpoint": {"id": ag.get("id"), "name": clean(ag.get("name"))},
            "decided_by": r.get("decided_by"), "updated_at": r.get("updated_at")}


# ------------------------------------------------------------------ endpoints
def p_limit(q, default=50):
    try:
        return max(1, min(MAX_LIMIT, int(q.get("limit", [default])[0])))
    except ValueError:
        raise ValueError("limit debe ser un número")


def p_window(q, default="24h"):
    w = q.get("window", [default])[0]
    if not WINDOW_RE.match(w):
        raise ValueError("window debe ser como 30m, 24h o 7d")
    return w


def ep_health(q):
    ok = True
    try:
        search(TS.ALERTS_INDEX, {"size": 0})
    except Exception:
        ok = False
    return {"status": "ok" if ok else "degraded", "service": "triplesoc-bff", "version": VERSION,
            "contract": TS.SCHEMA["contract"], "adapter": TS.ADAPTER}


def ep_summary(q):
    w = p_window(q)
    a = search(TS.ALERTS_INDEX, {"size": 0, "track_total_hits": True,
                                 "query": {"range": {F["timestamp"]: {"gte": f"now-{w}"}}},
                                 "aggs": {"crit": {"filter": TS.sev_gte(TS.CRITICAL)},
                                          "high": {"filter": TS.sev_range(TS.HIGH, TS.CRITICAL)},
                                          "eps": {"cardinality": {"field": F["agent_id"]}}}})
    i = search(INCIDENTS_INDEX, {"size": 0, "query": {"terms": {"status": ["new", "investigating"]}},
                                 "aggs": {"sev": {"terms": {"field": "severity"}}}})
    ag = a.get("aggregations") or {}
    return {"window": w, "alerts": a["hits"]["total"]["value"],
            "critical": (ag.get("crit") or {}).get("doc_count", 0), "high": (ag.get("high") or {}).get("doc_count", 0),
            "endpoints": (ag.get("eps") or {}).get("value", 0),
            "open_incidents": {b["key"]: b["doc_count"] for b in (i.get("aggregations") or {}).get("sev", {}).get("buckets", [])}}


def ep_alerts(q):
    w, lim = p_window(q), p_limit(q)
    sev = q.get("severity", [""])[0]
    filt = [{"range": {F["timestamp"]: {"gte": f"now-{w}"}}}]
    if sev:
        if sev not in BANDS:
            raise ValueError("severity debe ser critical, high o low")
        filt.append(TS.sev_range(*BANDS[sev]))
    r = search(TS.ALERTS_INDEX, {"size": lim, "sort": [{F["timestamp"]: "desc"}], "query": {"bool": {"filter": filt}},
                                 "_source": TS.source("alert_id", "timestamp", "agent", "rule_id", "severity",
                                                      "rule_description", "rule_mitre")})
    return {"window": w, "severity": sev or "all", "items": [alert_out(h["_source"]) for h in r["hits"]["hits"]]}


def ep_incidents(q):
    lim = p_limit(q)
    st = q.get("status", [""])[0]
    if st and not re.match(r"^[a-z_]{2,20}$", st):
        raise ValueError("status no válido")
    query = {"term": {"status": st}} if st else {"match_all": {}}
    r = search(INCIDENTS_INDEX, {"size": lim, "sort": [{"last_seen": "desc"}], "query": query})
    return {"status": st or "all", "items": [incident_out(h["_source"]) for h in r["hits"]["hits"]]}


def ep_responses(q):
    r = search(RESPONSES_INDEX, {"size": p_limit(q, 20), "sort": [{"updated_at": {"order": "desc", "unmapped_type": "date"}}],
                                 "query": {"match_all": {}}})
    return {"items": [response_out(h["_source"]) for h in r["hits"]["hits"]]}


ROUTES = {"/api/v1/health": ep_health, "/api/v1/summary": ep_summary, "/api/v1/alerts": ep_alerts,
          "/api/v1/incidents": ep_incidents, "/api/v1/responses": ep_responses}


class Handler(BaseHTTPRequestHandler):
    server_version = "TripleSOC-BFF/" + VERSION
    sys_version = ""

    def _send(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        u = urllib.parse.urlparse(self.path)
        fn = ROUTES.get(u.path)
        if not fn:
            return self._send(404, {"error": "not_found"})
        if u.path != "/api/v1/health":
            given = self.headers.get("Authorization", "")
            if not hmac.compare_digest(given.encode(), f"Bearer {TOKEN}".encode()):
                return self._send(401, {"error": "unauthorized"})
        try:
            return self._send(200, fn(urllib.parse.parse_qs(u.query)))
        except ValueError as e:
            return self._send(400, {"error": "bad_request", "detail": str(e)})
        except Exception as e:  # sin detalles internos hacia fuera
            self.log_message("error en %s: %s", u.path, type(e).__name__)
            return self._send(502, {"error": "upstream_error"})

    def log_message(self, fmt, *args):
        sys.stdout.write("[bff] %s - %s\n" % (self.address_string(), fmt % args))
        sys.stdout.flush()


def main():
    global AUTH, TOKEN
    AUTH, TOKEN = _auth_header(), _token()
    print(f"TripleSOC BFF {VERSION} en :{PORT} · contrato {TS.SCHEMA['contract']} · adaptador {TS.ADAPTER}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
