"""Fase 2 · prueba de la capa traductora en Python (sin red, dentro de la imagen de cada servicio).

  docker run --rm --network none -v /opt/triplesoc/src/ops:/t:ro triplesoc/responder:<tag> python /t/schema-test.py responder
  (igual con triplesoc/incidents:<tag> ... incidents  y  triplesoc/rulesmith:<tag> ... rulesmith)

Con el adaptador wazuh-4.x la capa tiene que producir EXACTAMENTE las consultas que antes estaban
escritas a mano (set de oro de abajo): así se demuestra que el cambio no altera el comportamiento.
Salida: una línea por caso y código 0 si todos pasan.
"""
import importlib
import sys

sys.path.insert(0, "/app")
import tsoc_schema as TS

fails = 0


def check(name, got, want):
    global fails
    ok = got == want
    fails += not ok
    print(f"  {'OK  ' if ok else 'FAIL'}  {name}" + ("" if ok else f"\n        obtenido: {got!r}\n        esperado: {want!r}"))


print(f"Capa traductora · contrato {TS.SCHEMA['contract']} · adaptador {TS.ADAPTER}")
# Set de oro: las consultas que había en el código antes de la capa (4.x).
check("índice de alertas", TS.ALERTS_INDEX, "triplesoc-alerts-*")
check("severidad >= 12", TS.sev_gte(TS.CRITICAL), {"range": {"rule.level": {"gte": 12}}})
check("severidad >= MIN_LEVEL (5)", TS.sev_gte(5), {"range": {"rule.level": {"gte": 5}}})
check("banda alta 7-11", TS.sev_range(gte=TS.HIGH, lt=TS.CRITICAL), {"range": {"rule.level": {"gte": 7, "lt": 12}}})
check("reglas por id", TS.by_rule_ids([100911, "100914"]), {"terms": {"rule.id": ["100911", "100914"]}})
check("reglas por grupo", TS.by_rule_group("syscheck"), {"term": {"rule.groups": "syscheck"}})
check("_source de incidents", TS.source("alert_id", "timestamp", "agent", "rule_id", "severity", "rule_description",
                                        "rule_groups", "rule_mitre"),
      ["id", "timestamp", "agent", "rule.id", "rule.level", "rule.description", "rule.groups", "rule.mitre"])
check("campos de agregación", (TS.F["agent_id"], TS.F["rule_description"], TS.F["rule_id"]),
      ("agent.id", "rule.description", "rule.id"))
doc = {"rule": {"level": 12, "id": "100911"}, "agent": {"id": "001", "name": "PC"}}
check("normalize (4.x = identidad)", TS.normalize(doc), doc)
check("severity(doc)", TS.severity(doc), 12)
check("bandas", [TS.band(n) for n in (3, 7, 11, 12, 15)], ["low", "high", "high", "critical", "critical"])
line = ('{"timestamp":"2026-10-20T10:00:00.000+0000","rule":{"level":12,"description":"TripleSOC Security: '
        'Unauthorized Device Detected","id":"100911","firedtimes":1},"agent":{"id":"001","name":"DESKTOP-3BPAU4P"}}')
check("línea cruda de alerts.json", (TS.raw_rule(line), TS.raw_agent_name(line)),
      ((12, "TripleSOC Security: Unauthorized Device Detected", "100911"), "DESKTOP-3BPAU4P"))
check("línea sin regla", TS.raw_rule('{"foo":1}'), None)

if len(sys.argv) > 1:  # el servicio carga la capa y no tiene su propio índice escrito a mano
    mod = importlib.import_module(sys.argv[1])
    check(f"{sys.argv[1]}.ALERTS_INDEX viene de la capa", mod.ALERTS_INDEX, TS.ALERTS_INDEX)
    check(f"{sys.argv[1]} usa tsoc_schema", getattr(mod, "TS", None) is TS, True)

print(f"RESULTADO: {'VERDE' if not fails else 'ROJO'} ({fails} fallos)")
sys.exit(1 if fails else 0)
