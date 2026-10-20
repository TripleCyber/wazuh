"""Capa traductora TripleSOC (anti-corrupción) para los servicios en Python.

Ningún servicio escribe a mano el nombre del índice de alertas ni los campos de Wazuh
(rule.level, rule.id, agent.name...): los toma de aquí. El contrato está en
triplesoc-schema.json, el mismo archivo que usa el dashboard (triplesoc-schema.js).

Severidad: TripleSOC trabaja siempre con su escala propia 0-16 (critical >= 12, high 7-11,
low < 7). Con Wazuh 4.x coincide con rule.level. Cuando Wazuh 5.x cambie el campo y sus
categorías, solo cambian este módulo y el JSON (adaptador "wazuh-5.x"); los servicios no.
"""
import json
import os
import re

_HERE = os.path.dirname(os.path.abspath(__file__))
SCHEMA_FILE = os.environ.get("TSOC_SCHEMA_FILE", os.path.join(_HERE, "triplesoc-schema.json"))

with open(SCHEMA_FILE, encoding="utf-8") as _f:
    SCHEMA = json.load(_f)

ADAPTER = SCHEMA["adapter"]
if ADAPTER != "wazuh-4.x":
    raise RuntimeError(f"adaptador {ADAPTER!r} sin implementar en tsoc_schema.py")

F = SCHEMA["fields"]
CRITICAL = int(SCHEMA["severity_bands"]["critical"])
HIGH = int(SCHEMA["severity_bands"]["high"])
# La variable de entorno sigue mandando (permite apuntar un canario a otro índice).
ALERTS_INDEX = os.environ.get("ALERTS_INDEX", SCHEMA["alerts_index"])


# ------------------------------------------------------------------ consultas
def sev_gte(level):
    """Filtro: severidad TripleSOC >= level."""
    return {"range": {F["severity"]: {"gte": int(level)}}}


def sev_range(gte=None, lt=None):
    r = {}
    if gte is not None:
        r["gte"] = int(gte)
    if lt is not None:
        r["lt"] = int(lt)
    return {"range": {F["severity"]: r}}


def by_agent(agent_id, match=False):
    return {"match" if match else "term": {F["agent_id"]: str(agent_id)}}


def by_rule_ids(ids):
    return {"terms": {F["rule_id"]: [str(x) for x in ids]}}


def by_rule_group(group):
    return {"term": {F["rule_groups"]: group}}


def source(*names):
    """Lista _source a partir de nombres lógicos (los que no están en el contrato pasan tal cual)."""
    return [F.get(n, n) for n in names]


# ------------------------------------------------------------------ documentos
def normalize(doc):
    """Documento de alerta del indexer -> forma canónica TripleSOC (la de 4.x: rule.level, agent...)."""
    return doc


def severity(doc):
    return int(((doc or {}).get("rule") or {}).get("level") or 0)


def band(level):
    level = int(level or 0)
    return "critical" if level >= CRITICAL else "high" if level >= HIGH else "low"


# ------------------------------------------------------------------ líneas crudas de alerts.json
# El carril rápido lee alerts.json sin decodificar el JSON entero; el formato de esa línea es de 4.x.
RAW_RULE_RE = re.compile(r'"rule":\{"level":(\d+),"description":"((?:[^"\\]|\\.)*)","id":"(\d+)"')
RAW_AGENT_RE = re.compile(r'"agent":\{"id":"\d+","name":"([^"]*)"')


def raw_rule(line):
    """(nivel, descripción, id) de una línea cruda de alerts.json, o None."""
    m = RAW_RULE_RE.search(line)
    return (int(m.group(1)), m.group(2), m.group(3)) if m else None


def raw_agent_name(line):
    m = RAW_AGENT_RE.search(line)
    return m.group(1) if m else None
