#!/bin/bash
# Login único con Logto cuando Logto firma con EC (ES384). Idempotente.
# El validador "openid" del indexer (OpenSearch 2.19) solo admite claves RSA (ClassCastException ECKey -> RSAKey),
# pero el validador "jwt" sí admite ECDSA. El dashboard sigue usando OpenID (redirige a Logto) y envía el
# id_token como Bearer; aquí lo valida logto_jwt_auth_domain con la clave pública EC de Logto.
# - Respalda la configuración de seguridad.
# - Toma la clave de firma del JWKS de Logto y la deja en logto_jwt_auth_domain (exige issuer y audience).
# - Desactiva openid_auth_domain (no se borra).
# Si Logto rota su clave hay que volver a ejecutar este script (upgrade-check avisa si el kid cambia).
set -euo pipefail
S=${SID:-yf8u7icjiq4vdhetmea7rmfr}; I=wazuh-indexer-$S
ISSUER=${OIDC_ISSUER:-https://auth.idp.tripleenable.com/oidc}
AUD=${OIDC_CLIENT_ID:-pdyo0aai6irvs2gbibgxs}
B=${BACKUP:-/opt/triplesoc/backup-$(date +%Y%m%d-%H%M)-oidc}
C=/usr/share/wazuh-indexer/config/certs
SA="/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cacert $C/root-ca.pem -cert $C/admin.pem -key $C/admin-key.pem -icl -nhnv -h localhost"
JH="export JAVA_HOME=/usr/share/wazuh-indexer/jdk"
mkdir -p /opt/triplesoc/oidc

mkdir -p "$B"; chmod 700 "$B"
docker exec "$I" bash -c "$JH; rm -rf /tmp/sec; mkdir /tmp/sec; $SA -backup /tmp/sec >/dev/null"
docker cp "$I:/tmp/sec" "$B/security" >/dev/null
docker exec "$I" rm -rf /tmp/sec
chmod -R go-rwx "$B"
echo "respaldo: $B/security"

curl -sf "$ISSUER/jwks" > "$B/jwks.json"
python3 - "$B/jwks.json" "$B/security/config.yml" "$B/config-jwt.yml" "$ISSUER" "$AUD" <<'PY'
import base64, json, re, sys
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec, rsa
jwks, src, dst, issuer, aud = sys.argv[1:6]
keys = [k for k in json.load(open(jwks))["keys"] if k.get("use", "sig") == "sig"]
if len(keys) != 1:
    sys.exit("JWKS con %d claves de firma: revisar a mano" % len(keys))
k = keys[0]
b = lambda s: int.from_bytes(base64.urlsafe_b64decode(s + "=" * (-len(s) % 4)), "big")
if k["kty"] == "EC":
    curve = {"P-256": ec.SECP256R1(), "P-384": ec.SECP384R1(), "P-521": ec.SECP521R1()}[k["crv"]]
    pub = ec.EllipticCurvePublicNumbers(b(k["x"]), b(k["y"]), curve).public_key()
else:
    pub = rsa.RSAPublicNumbers(b(k["e"]), b(k["n"])).public_key()
der = pub.public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)
key_b64 = base64.b64encode(der).decode()
open("/opt/triplesoc/oidc/logto-kid", "w").write(k["kid"] + "\n")
print("clave Logto: %s %s kid=%s..." % (k["kty"], k.get("crv", k.get("alg")), k["kid"][:8]))

lines = open(src).read().split("\n")
# Quitar un bloque logto_jwt_auth_domain anterior (de su línea hasta el siguiente dominio con 6 espacios).
if any("logto_jwt_auth_domain:" in l for l in lines):
    s = next(n for n, l in enumerate(lines) if "logto_jwt_auth_domain:" in l)
    e = next(n for n in range(s + 1, len(lines)) if re.match(r"^ {6}\S", lines[n]) or re.match(r"^ {0,4}\S", lines[n]))
    del lines[s:e]
i = next(n for n, l in enumerate(lines) if re.match(r"^    authc:\s*$", l))
block = """      logto_jwt_auth_domain:
        description: "Login unico TripleSOC con Logto: id_token firmado con EC validado como JWT"
        http_enabled: true
        transport_enabled: false
        order: 6
        http_authenticator:
          type: "jwt"
          challenge: false
          config:
            signing_key: "%s"
            jwt_header: "Authorization"
            subject_key: "sub"
            roles_key: "roles"
            required_issuer: "%s"
            required_audience: "%s"
            jwt_clock_skew_tolerance_seconds: 30
        authentication_backend:
          type: "noop\"""" % (key_b64, issuer, aud)
lines[i + 1:i + 1] = block.split("\n")
print("config: logto_jwt_auth_domain (sub/roles, issuer y audience exigidos)")
# Desactivar el validador openid (falla con claves EC).
if any("openid_auth_domain:" in l for l in lines):
    o = next(n for n, l in enumerate(lines) if "openid_auth_domain:" in l)
    for n in range(o, o + 8):
        if "http_enabled: true" in lines[n]:
            lines[n] = lines[n].replace("http_enabled: true", "http_enabled: false")
            print("config: openid_auth_domain desactivado")
            break
open(dst, "w").write("\n".join(lines))
PY
chmod 600 "$B/config-jwt.yml"
docker exec -u 0 "$I" rm -f /tmp/config-jwt.yml
docker exec -i "$I" bash -c 'cat > /tmp/config-jwt.yml' < "$B/config-jwt.yml"
docker exec "$I" bash -c "$JH; $SA -f /tmp/config-jwt.yml -t config | tail -2; rm -f /tmp/config-jwt.yml"
echo "indexer-jwt-ec: HECHO"
