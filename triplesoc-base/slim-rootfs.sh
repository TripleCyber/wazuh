#!/bin/sh
# Arma en $1 (por defecto /rootfs) un sistema mínimo para ejecutar Python, sin BusyBox ni apk-tools (GPL-2.0).
# Se ejecuta dentro de python:3.12-alpine, en la primera etapa del Dockerfile de cada servicio TripleSOC;
# la imagen final parte de scratch y solo copia este directorio. Deja en $R/usr/share/triplesoc/ la lista de
# librerías con su paquete y licencia, y falla si alguna es GPL sin excepción (LGPL y GCC runtime sí valen).
set -eu
R=${1:-/rootfs}
PYLIB=$(python -c 'import sysconfig; print(sysconfig.get_path("stdlib"))')

# Módulos que enlazan librerías GPL y que los servicios no usan: readline y gdbm (_gdbm, _dbm) son GPL-3.0;
# nis (obsoleto) arrastra libnsl, libtirpc, Kerberos, keyutils y com_err.
rm -f "$PYLIB"/lib-dynload/readline.*.so "$PYLIB"/lib-dynload/_gdbm.*.so "$PYLIB"/lib-dynload/_dbm.*.so \
      "$PYLIB"/lib-dynload/nis.*.so

# Intérprete y biblioteca estándar, sin pruebas, IDLE, tkinter ni pip (no hacen falta en ejecución).
mkdir -p "$R/usr/local" "$R/lib" "$R/etc/ssl/certs" "$R/usr/share/triplesoc"
cp -a /usr/local/bin /usr/local/lib "$R/usr/local/"
RPYLIB="$R$PYLIB"
rm -rf "$RPYLIB/test" "$RPYLIB/idlelib" "$RPYLIB/tkinter" "$RPYLIB/turtledemo" "$RPYLIB/ensurepip" \
       "$RPYLIB/site-packages/pip" "$RPYLIB"/site-packages/pip-*.dist-info
rm -f "$R"/usr/local/bin/pip* "$R"/usr/local/bin/idle* "$R"/usr/local/bin/pydoc* "$R"/usr/local/bin/*-config
find "$R/usr/local" -name '__pycache__' -type d -prune -exec rm -rf {} +

# Cargador de musl (MIT) y las librerías que piden el intérprete y sus módulos (incluidos los de site-packages).
cp -L /lib/ld-musl-*.so.1 "$R/lib/"
find "$R/usr/local" -type f \( -name '*.so' -o -name '*.so.*' -o -path '*/bin/python3*' \) | while read -r f; do
  ldd "$f" 2>/dev/null || true
done | awk '$2 == "=>" && $3 ~ /^\// { print $3 }' | sort -u > /tmp/libs.txt
while read -r l; do
  case "$l" in /usr/local/*|"$R"/*|*/../*) continue ;; esac
  mkdir -p "$R$(dirname "$l")"
  cp -L "$l" "$R$l"
done < /tmp/libs.txt

# Certificados raíz (MPL-2.0, sin modificar): los usa ssl.create_default_context() para hablar con la IA.
cp -L /etc/ssl/certs/ca-certificates.crt "$R/etc/ssl/certs/ca-certificates.crt"
cp -L /etc/ssl/cert.pem "$R/etc/ssl/cert.pem"

# Usuario sin privilegios de los servicios (uid 10001) y /tmp para el latido del healthcheck.
printf 'root:x:0:0:root:/root:/sbin/nologin\ntsoc:x:10001:10001:tsoc:/tmp:/sbin/nologin\n' > "$R/etc/passwd"
printf 'root:x:0:\ntsoc:x:10001:\n' > "$R/etc/group"
mkdir -p "$R/tmp" && chmod 1777 "$R/tmp"

# Inventario de lo copiado del sistema: librería, paquete de Alpine y su licencia.
out="$R/usr/share/triplesoc/librerias-sistema.txt"
echo "# Librerías de sistema de esta imagen (paquete Alpine y licencia)" > "$out"
bad=0
for l in /lib/ld-musl-*.so.1 /etc/ssl/certs/ca-certificates.crt $(cat /tmp/libs.txt); do
  case "$l" in /usr/local/*|"$R"/*|*/../*) continue ;; esac
  pkg=$(apk info -W "$(readlink -f "$l")" 2>/dev/null | sed -n 's/.* is owned by //p' | head -1)
  lic=$(apk list -I 2>/dev/null | grep "^$pkg " | sed -n 's/.*(\(.*\)).*/\1/p' | tail -1)
  echo "$l  $pkg  ${lic:-?}" >> "$out"
  case "$lic" in
    *LGPL*|*GCC-exception*|*"WITH "*) ;;
    *GPL*) echo "ERROR: $l ($pkg) es $lic" >&2; bad=1 ;;
  esac
done
cat "$out"
[ "$bad" -eq 0 ] || { echo "ERROR: la imagen mínima llevaría una librería GPL" >&2; exit 1; }
rm -f /tmp/libs.txt
