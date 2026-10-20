"""Inventario de licencias para la revisión legal (documento enjambre, punto 1 de los 30 días).

Lee los SBOM CycloneDX que deja ops/sbom.sh y escribe LICENCIAS.md en la misma carpeta:
  python3 /opt/triplesoc/src/ops/licencias.py /opt/triplesoc/sbom/ultimo
Por imagen: componentes por familia de licencia y la lista completa de los de copia fuerte
(GPL, AGPL, LGPL), que son los que el abogado tiene que revisar. No es asesoría legal: es la entrada
de datos para quien la haga.
"""
import collections
import glob
import json
import os
import sys

D = sys.argv[1] if len(sys.argv) > 1 else "."
STRONG = ("AGPL", "GPL", "LGPL")


def lic_of(c):
    out = []
    for l in c.get("licenses") or []:
        if "expression" in l:
            out.append(l["expression"])
        lic = l.get("license") or {}
        if lic.get("id") or lic.get("name"):
            out.append(lic.get("id") or lic.get("name"))
    return " OR ".join(dict.fromkeys(out)) or "SIN DECLARAR"


def family(s):
    u = s.upper()
    if "AGPL" in u:
        return "AGPL"
    if "LGPL" in u:
        return "LGPL"
    if "GPL" in u:
        return "GPL"
    if "APACHE" in u:
        return "Apache"
    if "MIT" in u:
        return "MIT"
    if "BSD" in u:
        return "BSD"
    if "MPL" in u:
        return "MPL"
    return "Sin declarar" if s == "SIN DECLARAR" else "Otras"


L = ["# Inventario de licencias TripleSOC", "",
     f"Fuente: SBOM CycloneDX de `{os.path.realpath(D)}` (ops/sbom.sh). No es asesoría legal: es la entrada para la revisión.", ""]
summary, strong_rows = [], []
for f in sorted(glob.glob(os.path.join(D, "*.cdx.json"))):
    img = os.path.basename(f)[:-len(".cdx.json")]
    comps = json.load(open(f, encoding="utf-8")).get("components") or []
    fam = collections.Counter()
    for c in comps:
        l = lic_of(c)
        fa = family(l)
        fam[fa] += 1
        if fa in STRONG:
            strong_rows.append((img, fa, c.get("name"), c.get("version") or "", l, c.get("type") or ""))
    summary.append((img, len(comps), fam))

fams = ["Apache", "MIT", "BSD", "MPL", "GPL", "LGPL", "AGPL", "Otras", "Sin declarar"]
L += ["## Resumen por imagen", "", "| Imagen | Componentes | " + " | ".join(fams) + " |", "|---|---:|" + "---:|" * len(fams)]
L += [f"| `{i}` | {n} | " + " | ".join(str(fa.get(x, 0)) for x in fams) + " |" for i, n, fa in summary]
L += ["", f"## Componentes de copia fuerte (GPL / LGPL / AGPL): {len(strong_rows)}", "",
      "| Imagen | Familia | Componente | Versión | Licencia declarada | Tipo |", "|---|---|---|---|---|---|"]
L += [f"| `{r[0]}` | {r[1]} | {r[2]} | {r[3]} | {r[4][:60]} | {r[5]} |" for r in sorted(strong_rows)]
open(os.path.join(D, "LICENCIAS.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")
agpl = sum(1 for r in strong_rows if r[1] == "AGPL")
print(f"LICENCIAS.md: {len(summary)} imágenes, {len(strong_rows)} componentes GPL/LGPL/AGPL ({agpl} AGPL)")
