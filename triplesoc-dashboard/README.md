# triplesoc-dashboard

Capa visual **TripleSOC** para `wazuh/wazuh-dashboard`, empaquetada como imagen Docker.
Nada se edita a mano en el servidor: la marca se inyecta al construir la imagen, así que
una actualización de Wazuh solo requiere reconstruir con la nueva versión base.

## Qué cambia

| Área | Cambio |
|---|---|
| Logos | Logo TripleSOC propio en SVG (escudo con flechas roja y verde, "Triple" verde + "SOC" rojo), estilo triplecyber.com/products/triplesoc. Encabezado, spinner, login, logos del plugin, reportes PDF, marcas de OpenSearch |
| Copias con hash | Se detectan por contenido (md5) en `*/target/public/`, sin depender de nombres que cambian entre versiones |
| Favicons | Generados desde `brand/mark.svg.tpl` (PNG + ICO + manifest) |
| Título | `applicationTitle` por defecto → `TripleSOC` |
| Tema | Modo oscuro activado por defecto (`theme:darkMode`); cada usuario puede cambiarlo en Advanced settings |
| Colores | Estilo TripleCyber: carbón neutro, verde #1AA54A (acento) / #13843B (botones, AA), rojo #BB2227 (crítico), gris #4A4A4A. Primarios EUI claro (#006BB4) y oscuro (#1BA9F5) → `brand/brand.env` en los CSS compilados + capa `overlay/triplesoc.css.tpl` (tipografía Roboto con respaldo Segoe UI/Inter) |
| Soporte externo | Menú de ayuda oculto, enlaces a wazuh.com / GitHub / Slack / Google Groups / opensearch.org ocultos, aviso "New release" oculto |
| Reportes | Correo y empresa por defecto de cabecera/pie |

## Estructura

```
brand/brand.env          paleta, título, datos de reportes
brand/*.svg.tpl          logos (plantillas con variables de brand.env)
overlay/triplesoc.css.tpl  capa CSS
scripts/apply-branding.sh  aplica todo sobre el árbol original (etapa "patcher")
Dockerfile               multi-stage: base oficial → patcher → base + archivos modificados
build.sh                 build con versión como argumento
```

## Uso

```bash
./build.sh 4.14.7                       # construye triplesoc/wazuh-dashboard:4.14.7
IMAGE=registry/org/wazuh-dashboard PUSH=1 ./build.sh 4.14.7
```

En el compose del stack, el servicio del dashboard usa la imagen construida:

```yaml
wazuh-dashboard:
  image: 'triplesoc/wazuh-dashboard:4.14.7'
  pull_policy: never        # imagen local (quitar si se usa un registry)
```

## Actualizar Wazuh

1. `./build.sh 4.14.8`
2. Cambiar el tag en el compose (dashboard, y manager/indexer a la misma versión) y reiniciar.

Si la nueva versión movió un punto de marca **obligatorio** (logo del encabezado, login,
favicon, título o la hoja `wz_v7_theme_overwrite.css`), el build falla con
`[triplesoc] ERROR: …` en lugar de publicar una imagen con la marca original.
Los puntos opcionales que falten solo se registran como `(omitido…)`.

## Cambiar la marca

Editar `brand/brand.env` o los `.svg.tpl` y reconstruir. Para usar un logo oficial
distinto, reemplazar el contenido de `logo*.svg.tpl` / `mark*.svg.tpl` manteniendo el nombre.
