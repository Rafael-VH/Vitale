# Arquitectura

Vitale está organizado en módulos pequeños con una responsabilidad clara cada uno. El JavaScript se divide en capas que se cargan en orden y comparten el namespace global `window.Vitale`.

[← Volver al README](../README.md)

---

## Estructura de carpetas

```
prototipe/
├── index.html                      ← Estructura HTML + carga de scripts
├── styles.css                      ← Hoja de estilos única y centralizada
└── js/
    ├── core/                       ← Utilidades sin dependencias
    │   ├── utils.js                → esc, alertMsg, contadores, portapapeles, descarga
    │   ├── mhtml-parser.js         → Detección y parseo de MHTML
    │   └── charset.js              → Lectura de archivos con detección de charset
    │
    ├── extractors/                 ← Extractores por sitio (auto-registrables)
    │   ├── registry.js             → Registro central de extractores
    │   ├── base.js                 → Helpers compartidos (selectores, genérico)
    │   ├── fanfiction.js           → Extractor Fanfiction.net
    │   ├── ao3.js                  → Extractor Archive of Our Own
    │   ├── webnovel.js             → Extractor Webnovel
    │   ├── royalroad.js            → Extractor Royal Road
    │   ├── wikipedia.js            → Extractor Wikipedia
    │   ├── substack.js             → Extractor Substack
    │   └── blogger.js              → Extractor Blogger
    │
    ├── platform.js                 ← Detección Android/iOS/desktop + textos del asistente
    ├── site-detector.js            ← Extrae URL del MHTML y clasifica el sitio
    ├── mdream-loader.js            ← Carga dinámica del motor mdream
    ├── download-modal.js           ← Modal de descarga
    ├── convert-panel.js            ← Lógica del tab "Convertir HTML"
    ├── assist-panel.js             ← Lógica del tab "Obtener de URL"
    └── main.js                     ← Bootstrap: une todo y arranca la app
```

**Total: 20 archivos** (3 core + 9 extractores + 6 servicios + 2 paneles) + HTML + CSS.

---

## Capas y responsabilidades

### Core (`js/core/`)

Utilidades transversales sin dependencias de otras capas.

- **`utils.js`** — Escapado HTML, gestión de alertas, contadores, portapapeles (con fallback), descarga de archivos (con BOM UTF-8).
- **`mhtml-parser.js`** — Detección de MHTML, extracción de boundary, decodificación quoted-printable y base64, selección de la parte `text/html` más grande.
- **`charset.js`** — Lectura de archivos con detección automática del charset desde `<meta charset>`.

### Extractores (`js/extractors/`)

Sistema extensible para aislar el contenido principal por sitio.

- **`registry.js`** — Registro central. Cada extractor llama a `Vitale.extractors.register()` al cargarse.
- **`base.js`** — Helpers compartidos: `extractBySelectors()`, `extractGeneric()` y la cascada `extractMainContent()`.
- **`<sitio>.js`** — Un archivo por sitio con sus dominios y selectores.

### Servicios

- **`platform.js`** — Detección de Android / iOS / desktop + generación dinámica de los textos del asistente según plataforma.
- **`site-detector.js`** — Extrae la URL del MHTML, clasifica el sitio, orquesta el pipeline `MHTML → HTML → extractor → Markdown`.
- **`mdream-loader.js`** — Carga dinámica del motor mdream desde jsDelivr + wrapper de conversión con validación.
- **`download-modal.js`** — Modal para elegir el nombre del archivo antes de descargar.

### Paneles

- **`convert-panel.js`** — Toda la lógica del tab principal: carga, drag & drop, pegado, conversión, limpieza.
- **`assist-panel.js`** — Toda la lógica del asistente de URLs.

### Bootstrap

- **`main.js`** — Punto de entrada. Inicializa todo, conecta las pestañas y arranca la carga del motor.

---

## Flujo de procesamiento de un MHTML

```
Usuario carga archivo .mhtml
    ↓
convert-panel.js → lee con charset.js (detecta UTF-8/Latin-1/…)
    ↓
site-detector.js → ¿es MHTML?
    │
    ├── Sí → mhtml-parser.js → extrae el HTML interno
    │       site-detector.js → extrae URL original y clasifica sitio
    │       extractorBase.extractMainContent(html, siteKey)
    │           ↓
    │       ¿Existe extractor para ese sitio?
    │           ├── Sí → applyExtractor() → selectores CSS → custom()
    │           └── No → extractGeneric()
    │
    └── No → extractorBase.extractMainContent(html, siteKey) directamente
    ↓
mdream-loader.js → convierte el HTML limpio a Markdown
    ↓
download-modal.js → guarda el .md con UTF-8 + BOM
```

---

## Orden de carga de scripts

El orden en `index.html` importa porque todos los archivos comparten el namespace `window.Vitale`:

1. **Core** → define utilidades que no dependen de nadie.
2. **Extractores** → `registry.js` y `base.js` primero, luego cada extractor se auto-registra.
3. **Servicios** → dependen de core y de extractores.
4. **Paneles** → dependen de todo lo anterior.
5. **`main.js`** → bootstrap final.

Si añades un archivo nuevo, respeta este orden. Por ejemplo, un extractor nuevo va entre `blogger.js` y el cierre del grupo de extractores.

---

## Cómo funciona el registry de extractores

Cada archivo extractor ejecuta código al cargarse que llama a `Vitale.extractors.register(nombre, config)`. El registry almacena estas configuraciones en un `Map` y expone métodos para consultarlas:

- `registry.get(name)` — devuelve la config de un extractor.
- `registry.has(name)` — comprueba si existe.
- `registry.list()` — lista de nombres registrados.
- `registry.allDomains()` — mapa dominio → nombre de extractor.
- `registry.labelOf(name)` — nombre legible para el pill.

Esto permite que el `site-detector.js` no conozca la lista de sitios de antemano. Solo pregunta al registry qué dominios están cubiertos.

---

## Cómo funciona el fallback en cascada

Cuando un extractor específico falla (porque el sitio cambió su HTML), el flujo sigue así:

1. `applyExtractor()` devuelve `null` si ningún selector encontró contenido válido (mínimo 200 caracteres).
2. `extractMainContent()` cae al `extractGeneric()`.
3. Si el genérico tampoco encuentra nada, devuelve el HTML completo.
4. La conversión con mdream **nunca falla** por culpa de un extractor. Como mucho, produce un Markdown con algo más de ruido.

Esto garantiza que añadir o modificar extractores **nunca rompe la app**.

---

## Cómo migrar a Flutter

Cada capa se traduce directamente a Dart:

| Módulo JS | Equivalente Dart |
|---|---|
| `core/utils.js` | Utilidades estáticas en `lib/core/utils/` |
| `core/mhtml-parser.js` | `MhtmlParserDataSource` en `lib/features/convert/data/datasources/` |
| `core/charset.js` | `CharsetDetector` en `lib/core/utils/` |
| `extractors/registry.js` | `Map<String, ExtractorConfig>` en `domain/repositories/` |
| `extractors/<sitio>.js` | Una clase `Extractor` por sitio en `data/extractors/` |
| `platform.js` | `PlatformProvider` en `shared/providers/` |
| `site-detector.js` | `ConversionRepositoryImpl` |
| `mdream-loader.js` | `MarkdownEngineDataSource` |
| `download-modal.js` | Widget `DownloadDialog` |
| `convert-panel.js` | `ConvertPage` + `ConvertController` |
| `assist-panel.js` | `AssistPage` + `AssistController` |
| `main.js` | `main.dart` + `app.dart` |