# Sitios soportados

Vitale incluye extractores específicos para los siguientes sitios. Cada uno conoce la estructura del HTML de ese sitio en concreto y sabe aislar el contenido del capítulo o artículo, descartando menús, cabeceras y publicidad.

[← Volver al README](../README.md)

---

## Tabla de sitios

| Sitio | Dominio | Selectores CSS | Notas |
|---|---|---|---|
| **Fanfiction.net** | `fanfiction.net`<br>`m.fanfiction.net` | `#storycontent` | Incluye regex específico que limpia residuos del sitio |
| **Archive of Our Own** | `archiveofourown.org` | `#chapters .userstuff`<br>`#workskin .userstuff`<br>`.userstuff` | Concatena todos los capítulos si están en la misma página |
| **Webnovel** | `webnovel.com` | `.cha-content`<br>`.cha-words`<br>`#chapter-content`<br>`.chapter-content` | Prueba varios contenedores porque la estructura ha cambiado varias veces |
| **Royal Road** | `royalroad.com` | `.chapter-content`<br>`.chapter-inner` | Muy estable |
| **Wikipedia** | `wikipedia.org` | `#mw-content-text .mw-parser-output`<br>`#mw-content-text` | Estructura MediaWiki estándar |
| **Substack** | `substack.com` | `.body.markup`<br>`.available-content .body` | Incluye subdominios personalizados |
| **Blogger** | `blogspot.com` | `.post-body.entry-content`<br>`.post-body` | Estructura estándar de la plataforma |

### Cualquier otro dominio

Si el dominio no está en la lista, Vitale usa automáticamente el **extractor genérico** con patrones amplios sobre:

- `<article>` o `<div>` con clases o IDs que contengan `story`, `chapter`, `post`, `article` o `content`.
- Si nada coincide, devuelve el HTML completo sin filtrar.

Esto significa que **siempre obtienes algo**, aunque sea con algo más de ruido.

---

## Cómo se detecta el sitio

Vitale extrae la URL original del MHTML buscando, en este orden:

1. `Snapshot-Content-Location` — cabecera propietaria de Chrome, Edge, Brave, Vivaldi.
2. `Content-Location` — estándar MIME, presente en todas las partes del MHTML.
3. `<link rel="canonical">` — dentro del HTML.
4. `<meta property="og:url">` — dentro del HTML.

Con esa URL se identifica el dominio y se busca un extractor registrado para él. El resultado se muestra en la barra de estado como un **pill violeta** con el nombre del sitio (por ejemplo `🌐 Fanfiction`).

---

## Cómo añadir soporte para un sitio nuevo

Añadir un sitio es **crear un archivo y registrarlo**. No hay que tocar nada más.

### Paso 1: crear el archivo del extractor

Crea `prototipe/js/extractors/mi-sitio.js` con este contenido:

```javascript
/* ============================================================================
   VITALE — Extractor: Mi Sitio
   ========================================================================== */

window.Vitale = window.Vitale || {};

Vitale.extractors.register('mi-sitio', {
  label: 'Mi Sitio',
  domains: ['misitio.com'],
  selectors: ['#contenido-principal', '.post-content']
});
```

### Paso 2: añadirlo al index.html

En `prototipe/index.html`, añade una línea junto a los demás extractores:

```html
<script src="js/extractors/mi-sitio.js"></script>
```

### Paso 3: probar

1. Abre el sitio en el navegador y localiza el contenedor del contenido con las DevTools (`F12` → pestaña Elements).
2. Ejecuta en la consola `document.querySelector('tu-selector')` para verificar que coincide.
3. Guarda la página como MHTML, cárgala en Vitale y verifica que el pill muestra **🌐 Mi Sitio**.

---

## Estructura de la configuración del extractor

Un extractor acepta los siguientes campos:

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `label` | `string` | Sí | Nombre visible en el pill de la barra de estado |
| `domains` | `string[]` | Sí | Lista de dominios cubiertos. Soporta subdominios automáticamente (`m.misitio.com` coincide con `misitio.com`) |
| `selectors` | `string[]` | Recomendado | Selectores CSS que se prueban en orden. El primero que devuelva contenido válido gana |
| `custom` | `function(html)` | Opcional | Función personalizada que recibe el HTML completo y devuelve solo el contenido o `null`. Útil cuando los selectores no bastan |

### Ejemplo con `custom`

Fanfiction.net usa un `custom` porque el selector `#storycontent` devuelve a veces residuos del sitio:

```javascript
Vitale.extractors.register('fanfiction', {
  label: 'Fanfiction',
  domains: ['fanfiction.net'],
  selectors: ['#storycontent'],
  custom: function(html){
    const m = html.match(
      /<div[^>]*id="storycontent"[^>]*>([\s\S]*?)<\/div>\s*(?:<hr|<div\s+align="center"|<div class="drop_m")/i
    );
    return m && m[1] && m[1].length > 200 ? '<div>' + m[1] + '</div>' : null;
  }
});
```

### Orden de intento

Cuando Vitale procesa un HTML de un sitio conocido:

1. Prueba los **selectores CSS** en orden (con `querySelectorAll`, concatenando todos los resultados).
2. Si ninguno funciona, prueba la función **`custom`**.
3. Si tampoco, cae al **extractor genérico**.
4. Si el genérico no encuentra nada, devuelve el **HTML completo**.

---

## Tabla de extractores registrados actualmente

Para ver la lista en vivo, abre la consola del navegador al iniciar Vitale. Verás una línea como:

```
[Vitale] Extractores registrados: ['fanfiction', 'ao3', 'webnovel', 'royalroad', 'wikipedia', 'substack', 'blogger']
```

Esta lista se genera automáticamente desde el registry.