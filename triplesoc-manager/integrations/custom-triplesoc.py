#!/usr/bin/env python3
"""Integración TripleSOC: reestructura alertas críticas y las envía por webhook.

La invoca wazuh-integratord con:  <alert_file> <api_key> <hook_url>
El payload es un esquema propio (triplesoc.alert/v1): no reenvía la estructura
original del motor, incluye siempre "vendor": "TripleSOC" y reescribe cualquier
referencia textual al fabricante. El campo "text" permite verlo directamente en
Slack / Microsoft Teams (webhooks entrantes).
"""
import json
import os
import re
import ssl
import sys
import time
import urllib.error
import urllib.request

LOG_FILE = "/var/ossec/logs/integrations.log"
SCHEMA = "triplesoc.alert/v1"
VENDOR_TRACE = re.compile(r"wazuh|ossec", re.IGNORECASE)
MAX_EVIDENCE = 2000
TIMEOUT = 10


def log(msg):
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as fh:
            fh.write(f"{time.strftime('%Y/%m/%d %H:%M:%S')} custom-triplesoc: {msg}\n")
    except OSError:
        pass


def scrub(value):
    """Reescribe rastros del fabricante en cualquier texto del payload."""
    if isinstance(value, str):
        return VENDOR_TRACE.sub("TripleSOC", value)
    if isinstance(value, list):
        return [scrub(v) for v in value]
    if isinstance(value, dict):
        return {k: scrub(v) for k, v in value.items()}
    return value


def severity_label(level):
    # Nivel 12 o superior se considera crítico en TripleSOC.
    if level >= 12:
        return "critical"
    if level >= 7:
        return "high"
    if level >= 4:
        return "medium"
    return "low"


def build_payload(alert):
    rule = alert.get("rule", {})
    agent = alert.get("agent", {})
    level = int(rule.get("level", 0))
    mitre = rule.get("mitre", {})

    compliance = {
        key: rule[key]
        for key in ("pci_dss", "gdpr", "hipaa", "nist_800_53", "tsc", "gpg13")
        if rule.get(key)
    }
    evidence = alert.get("full_log") or ""
    if len(evidence) > MAX_EVIDENCE:
        evidence = evidence[:MAX_EVIDENCE] + "…"

    payload = {
        "vendor": "TripleSOC",
        "schema": SCHEMA,
        "event_id": alert.get("id"),
        "occurred_at": alert.get("timestamp"),
        "severity": {"score": level, "label": severity_label(level), "priority": "P1" if level >= 12 else "P3"},
        "title": rule.get("description", "Evento de seguridad"),
        "detection": {
            "signature_id": rule.get("id"),
            "categories": rule.get("groups", []),
            "hits": rule.get("firedtimes"),
            "mitre_attack": {
                "tactics": mitre.get("tactic", []),
                "techniques": mitre.get("technique", []),
                "technique_ids": mitre.get("id", []),
            },
            "compliance": compliance,
        },
        "asset": {"name": agent.get("name"), "address": agent.get("ip"), "ref": agent.get("id")},
        "source": {"channel": alert.get("location")},
        "evidence": evidence,
    }
    payload = scrub(payload)

    sev = payload["severity"]
    payload["text"] = (
        f"[TripleSOC] {sev['label'].upper()} (nivel {sev['score']}) - {payload['title']}\n"
        f"Activo: {payload['asset']['name'] or 'n/d'}  |  Firma: {payload['detection']['signature_id']}  |  "
        f"{payload['occurred_at']}"
    )
    return payload


TEAMS_HOSTS = ("logic.azure.com", "powerplatform.com", "powerautomate", "webhook.office.com")


def is_teams(url):
    return any(h in url.lower() for h in TEAMS_HOSTS)


def teams_message(payload):
    """Mensaje para un Workflow de Teams ("Enviar alertas de webhook a un canal"):
    una Adaptive Card con los datos de la alerta. Conserva "vendor" y el esquema propio."""
    sev, asset, det = payload["severity"], payload["asset"], payload["detection"]
    mitre = det["mitre_attack"]
    facts = [
        {"title": "Severidad", "value": f"{sev['label'].upper()} (nivel {sev['score']}, {sev['priority']})"},
        {"title": "Activo", "value": f"{asset['name'] or 'n/d'} ({asset['address'] or 'sin IP'})"},
        {"title": "Firma", "value": str(det["signature_id"])},
        {"title": "Fecha", "value": str(payload["occurred_at"])},
    ]
    if mitre["technique_ids"]:
        facts.append({"title": "MITRE ATT&CK", "value": ", ".join(mitre["technique_ids"])})
    # Trazabilidad: el mismo identificador que la alerta tiene en el dashboard (campo "id").
    facts.append({"title": "ID de evento", "value": str(payload["event_id"])})
    facts.append({"title": "Buscar en TripleSOC", "value": f'Threat Hunting → id:"{payload["event_id"]}"'})
    body = [
        {"type": "TextBlock", "text": "TripleSOC Security", "weight": "Bolder", "size": "Small", "color": "Good"},
        {"type": "TextBlock", "text": payload["title"], "weight": "Bolder", "size": "Medium", "wrap": True,
         "color": "Attention" if sev["score"] >= 12 else "Default"},
        {"type": "FactSet", "facts": facts},
    ]
    if payload["evidence"]:
        body.append({"type": "TextBlock", "text": payload["evidence"][:600], "wrap": True, "isSubtle": True,
                     "fontType": "Monospace", "size": "Small"})
    return {
        "type": "message",
        "vendor": payload["vendor"],
        "schema": payload["schema"],
        "event_id": payload["event_id"],
        "attachments": [{
            "contentType": "application/vnd.microsoft.card.adaptive",
            "contentUrl": None,
            "content": {
                "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "type": "AdaptiveCard",
                "version": "1.4",
                "msteams": {"width": "Full"},
                "body": body,
            },
        }],
    }


def resolve_url(hook_url):
    """hook_url puede ser la URL o file:///ruta con la URL dentro (URLs con '&' o secretas,
    como las de Workflows de Teams, no se escriben en ossec.conf)."""
    if hook_url.startswith("file://"):
        with open(hook_url[len("file://"):], encoding="utf-8") as fh:
            return fh.read().strip()
    return hook_url


def ssl_context():
    """El Python embebido del manager apunta a un almacén de CAs inexistente
    (/usr/local/ssl/cert.pem): se usa certifi o el bundle del sistema, con verificación activa."""
    candidates = []
    try:
        import certifi
        candidates.append(certifi.where())
    except ImportError:
        pass
    candidates += ["/etc/pki/tls/certs/ca-bundle.crt", "/etc/ssl/certs/ca-certificates.crt"]
    for path in candidates:
        if os.path.exists(path):
            return ssl.create_default_context(cafile=path)
    return ssl.create_default_context()


def send(url, payload):
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        url, data=data, method="POST",
        headers={"Content-Type": "application/json; charset=utf-8", "User-Agent": "TripleSOC-Integration/1.0"},
    )
    ctx = ssl_context() if url.lower().startswith("https://") else None
    with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as resp:
        return resp.status


def main(argv):
    if len(argv) < 4:
        log(f"argumentos insuficientes: {len(argv) - 1}")
        return 2
    alert_file, hook_url = argv[1], argv[3]
    try:
        with open(alert_file, encoding="utf-8") as fh:
            alert = json.load(fh)
    except (OSError, ValueError) as exc:
        log(f"no se pudo leer la alerta: {exc}")
        return 1

    payload = build_payload(alert)
    try:
        url = resolve_url(hook_url)
    except OSError as exc:
        log(f"no se pudo leer la URL del destino: {exc}")
        return 1
    target = "teams" if is_teams(url) else "webhook"
    if target == "teams":
        payload = teams_message(payload)
    try:
        status = send(url, payload)
        log(f"enviado ({target}) event_id={payload['event_id']} nivel={alert.get('rule', {}).get('level')} http={status}")
        return 0
    except (urllib.error.URLError, OSError) as exc:
        log(f"error enviando event_id={payload['event_id']}: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
