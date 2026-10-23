#!/usr/bin/env bash
# Genera los certificados TLS internos en ./certs: CA propia + indexer, manager, dashboard y admin.
#   sudo ./generate-certs.sh          (solo la primera vez; no pisa una CA que ya exista)
# Los nombres (SAN) son los nombres de host del compose (wazuh-indexer, wazuh-manager, wazuh-dashboard): Filebeat
# verifica el nombre del indexer. El generador oficial de Wazuh no admite nombres sin punto, por eso se usa openssl.
# Los sujetos coinciden con admin_dn / nodes_dn de config/wazuh_indexer/opensearch.yml. La carpeta certs/ NO va a git.
set -euo pipefail
cd "$(dirname "$0")"
D=certs DAYS=3650 SUBJ="/C=US/L=California/O=Wazuh/OU=Wazuh"
command -v openssl >/dev/null || { echo "falta openssl"; exit 1; }
mkdir -p "$D"
if [[ -f $D/root-ca.pem ]]; then echo "Ya existe $D/root-ca.pem: no se regenera nada (bórrese certs/ para empezar de cero)."; exit 0; fi

openssl req -x509 -new -nodes -newkey rsa:4096 -sha256 -days "$DAYS" -subj "$SUBJ/CN=root-ca" \
  -keyout $D/root-ca.key -out $D/root-ca.pem 2>/dev/null

cert() { # cert <archivo> <CN> [SAN]
  local f=$1 cn=$2 san=${3:-}
  openssl req -new -nodes -newkey rsa:2048 -sha256 -subj "$SUBJ/CN=$cn" -keyout $D/$f-key.pem -out $D/$f.csr 2>/dev/null
  {
    echo "basicConstraints=CA:FALSE"
    echo "keyUsage=critical,digitalSignature,keyEncipherment"
    echo "extendedKeyUsage=serverAuth,clientAuth"
    [[ -n $san ]] && echo "subjectAltName=$san"
  } > $D/$f.ext
  openssl x509 -req -in $D/$f.csr -CA $D/root-ca.pem -CAkey $D/root-ca.key -CAcreateserial -sha256 -days "$DAYS" \
    -extfile $D/$f.ext -out $D/$f.pem 2>/dev/null
  rm -f $D/$f.csr $D/$f.ext
}
cert admin           admin
cert wazuh-indexer   wazuh-indexer   "DNS:wazuh-indexer,DNS:localhost,IP:127.0.0.1"
cert wazuh-manager   wazuh-manager   "DNS:wazuh-manager"
cert wazuh-dashboard wazuh-dashboard "DNS:wazuh-dashboard"

# Certificados legibles; claves solo para quien las usa: el indexer corre como uid/gid 1000 (su clave y la de
# admin, que usan los scripts de setup dentro del indexer); Filebeat del manager corre como root.
chmod 644 $D/*.pem
chmod 600 $D/root-ca.key $D/wazuh-manager-key.pem $D/wazuh-dashboard-key.pem
chown 1000:1000 $D/wazuh-indexer-key.pem $D/admin-key.pem 2>/dev/null || true
chmod 640 $D/wazuh-indexer-key.pem $D/admin-key.pem
rm -f $D/root-ca.srl
for f in admin wazuh-indexer wazuh-manager wazuh-dashboard; do openssl verify -CAfile $D/root-ca.pem $D/$f.pem; done
ls -l $D
