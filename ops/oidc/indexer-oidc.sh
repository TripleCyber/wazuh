#!/bin/bash
# Login único con Logto (OpenID Connect) en el indexer. Idempotente: se puede repetir.
# - Respalda la configuración de seguridad entera (securityadmin -backup).
# - Añade openid_auth_domain SIN quitar el login de usuario/contraseña (sigue de respaldo).
# - Crea el rol tsoc_analista y mapea los roles de Logto (claim "roles") a los de OpenSearch.
# Volver atrás: securityadmin -f <respaldo>/security/config.yml -t config (y roles/rolesmapping igual).
set -euo pipefail
S=${SID:-yf8u7icjiq4vdhetmea7rmfr}; I=wazuh-indexer-$S
OIDC_URL=${OIDC_URL:-https://auth.idp.tripleenable.com/oidc/.well-known/openid-configuration}
# sub: identificador estable de Logto (recomendado por el administrador de Logto; no todos los usuarios tienen email)
SUBJECT=${OIDC_SUBJECT:-sub}
B=${BACKUP:-/opt/triplesoc/backup-$(date +%Y%m%d-%H%M)-oidc}
C=/usr/share/wazuh-indexer/config/certs
SA="/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cacert $C/root-ca.pem -cert $C/admin.pem -key $C/admin-key.pem -icl -nhnv -h localhost"
JH="export JAVA_HOME=/usr/share/wazuh-indexer/jdk"

mkdir -p "$B"; chmod 700 "$B"
docker exec "$I" bash -c "$JH; rm -rf /tmp/sec; mkdir /tmp/sec; $SA -backup /tmp/sec >/dev/null"
docker cp "$I:/tmp/sec" "$B/security" >/dev/null
docker exec "$I" rm -rf /tmp/sec
chmod -R go-rwx "$B"
echo "respaldo: $B/security"

python3 - "$B/security/config.yml" "$B/config-oidc.yml" "$OIDC_URL" "$SUBJECT" <<'PY'
import re, sys
src, dst, url, subject = sys.argv[1:5]
lines = open(src).read().split("\n")
txt = "\n".join(lines)
if "openid_auth_domain:" not in txt:
    i = next(n for n, l in enumerate(lines) if re.match(r"^    authc:\s*$", l))
    block = """      openid_auth_domain:
        description: "Login unico TripleSOC con Logto (OpenID Connect)"
        http_enabled: true
        transport_enabled: true
        order: 5
        http_authenticator:
          type: "openid"
          challenge: false
          config:
            subject_key: "%s"
            roles_key: "roles"
            openid_connect_url: "%s"
        authentication_backend:
          type: "noop\"""" % (subject, url)
    lines[i + 1:i + 1] = block.split("\n")
    print("config: openid_auth_domain añadido (subject_key=%s)" % subject)
else:
    o = next(n for n, l in enumerate(lines) if "openid_auth_domain:" in l)
    for n in range(o, o + 16):
        if re.match(r"^\s+subject_key:", lines[n]):
            lines[n] = re.sub(r"subject_key:.*", 'subject_key: "%s"' % subject, lines[n])
            break
    print("config: openid_auth_domain ya estaba (subject_key=%s)" % subject)
# Con varios métodos de login, el básico no debe pedir contraseña al navegador (challenge).
b = next(n for n, l in enumerate(lines) if "basic_internal_auth_domain:" in l)
for n in range(b, b + 12):
    if "challenge: true" in lines[n]:
        lines[n] = lines[n].replace("challenge: true", "challenge: false")
        print("config: basic challenge -> false")
        break
open(dst, "w").write("\n".join(lines))
PY
chmod 600 "$B/config-oidc.yml"
docker exec -u 0 "$I" rm -f /tmp/config-oidc.yml
# Por stdin: con docker cp el archivo queda de root (600) y el usuario del contenedor no lo lee.
docker exec -i "$I" bash -c 'cat > /tmp/config-oidc.yml' < "$B/config-oidc.yml"
docker exec "$I" bash -c "$JH; $SA -f /tmp/config-oidc.yml -t config | tail -2; rm -f /tmp/config-oidc.yml"

python3 - "$I" <<'PY'
import json, subprocess, sys
I = sys.argv[1]
C = "/usr/share/wazuh-indexer/config/certs"
def q(method, path, body=None):
    cmd = ["docker", "exec", "-i", I, "curl", "-sk", "--cert", C + "/admin.pem", "--key", C + "/admin-key.pem",
           "-H", "Content-Type: application/json", "-X", method, "https://localhost:9200/_plugins/_security/api/" + path]
    if body is not None:
        cmd += ["--data-binary", "@-"]
    r = subprocess.run(cmd, input=(json.dumps(body) if body is not None else "").encode(), capture_output=True)
    return json.loads(r.stdout or b"{}")
print("rol tsoc_analista:", q("PUT", "roles/tsoc_analista", {
    "description": "TripleSOC analista: gestiona incidentes y respuestas",
    "cluster_permissions": ["cluster_composite_ops_ro"],
    "index_permissions": [{"index_patterns": ["triplesoc-incidents", "triplesoc-incidents-responses",
                                              "triplesoc-incidents-guardian"], "allowed_actions": ["crud"]}]}).get("status"))
WANT = {"all_access": ["tsoc-admin"], "tsoc_analista": ["tsoc-analista"],
        "readall": ["tsoc-analista", "tsoc-lectura"], "kibana_user": ["tsoc-analista", "tsoc-lectura"],
        "kibana_read_only": ["tsoc-lectura"]}
for role, roles in WANT.items():
    cur = q("GET", "rolesmapping/" + role).get(role, {})
    body = {k: cur.get(k, []) for k in ("backend_roles", "hosts", "users", "and_backend_roles")}
    if all(r in body["backend_roles"] for r in roles):
        print("mapeo %s: ya estaba" % role); continue
    body["backend_roles"] += [r for r in roles if r not in body["backend_roles"]]
    print("mapeo %s:" % role, q("PUT", "rolesmapping/" + role, body).get("status"), body["backend_roles"])
PY
echo "indexer-oidc: HECHO"
