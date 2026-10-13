# Vitale

**Convierte páginas web guardadas (HTML o MHTML) en Markdown limpio — sin instalar nada, sin cuentas y sin servidores.**

![Licencia: MIT](https://img.shields.io/badge/licencia-MIT-5eead4.svg?style=flat-square)
![Offline-first](https://img.shields.io/badge/offline--first-sí-34d399.svg?style=flat-square)
![Sin dependencias](https://img.shields.io/badge/dependencias-0-818cf8.svg?style=flat-square)
![Optimizado para LLMs](https://img.shields.io/badge/optimizado%20para-LLMs-a78bfa.svg?style=flat-square)

Vitale toma un archivo `.html` o `.mhtml` (el formato "Guardar página como" de Chrome, Edge, Firefox y Safari) y devuelve un `.md` limpio, sin menús, publicidad ni ruido. Todo el procesamiento ocurre **en tu navegador**: ningún dato sale de tu dispositivo.

Sirve para tres cosas: **leer offline** artículos y capítulos, **preparar contenido para LLMs** (el Markdown gasta muchos menos tokens que el HTML crudo) y **archivar** páginas que podrían desaparecer en un formato que sobrevive décadas.

## ⚡ Probar en un minuto

No hace falta instalar nada.

1. Clona el repositorio:

   ```bash
   git clone https://github.com/Rafael-VH/Vitale.git
   ```

2. Abre `prototipe/index.html` en tu navegador.
3. Arrastra un `.mhtml` guardado desde tu navegador y pulsa **Convertir a Markdown**.

> **Si el motor no carga al abrir con doble clic** (algunos navegadores bloquean `import()` desde `file://`), sirve la carpeta con un servidor local:
>
> ```bash
> cd prototipe
> python -m http.server 8000
> ```
>
> Luego abre <http://localhost:8000/>.

## 📦 Qué hay en este repositorio

El repositorio contiene **dos implementaciones** de Vitale:

| Ruta | Qué es | Estado |
| --- | --- | --- |
| `prototipe/` | App web vanilla (HTML + CSS + JS, 20 módulos, sin build) | ✅ En uso — versión 1.0 |
| `lib/` | Port a Flutter (Android, iOS, Web) con Clean Architecture + Riverpod | 🚧 En desarrollo — versión 2.0 |
| `docs/` | Documentación del proyecto | — |

El prototipo web es la **referencia funcional**: define el comportamiento que el port a Flutter reproduce.

## ✨ Características

### Conversión

- **HTML → Markdown** con [mdream](https://github.com/harlan-zw/mdream) (`@mdream/js`, cargado desde CDN).
- **Soporte nativo de MHTML/MHT**, el formato de "Guardar página como" de los navegadores.
- **Detección de charset**: UTF-8, ISO-8859-1, Windows-1252, Shift-JIS, GBK y más.
- **Descarga con BOM UTF-8**, para que los acentos se vean bien en cualquier visor.

### Extracción por sitio

- **Detección automática del sitio** a partir de la URL incrustada en el MHTML.
- **Extractores específicos** para sitios conocidos (ver tabla), mucho más precisos que el genérico.
- **Fallback en cascada**: extractor específico → genérico → HTML completo. La conversión nunca falla.
- **Pill de sitio** en la barra de estado mostrando qué sitio se reconoció.

### Entrada y salida

- Panel de carga con drag & drop, pegado desde el portapapeles y asistente para URLs.
- Modal para elegir el nombre del archivo antes de descargar.
- Copiado directo al portapapeles (Obsidian, Notion, VS Code…).

### Privacidad

- Cero servidores, cero telemetría, cero cuentas. Funciona offline después de la primera carga.

## 🌐 Sitios soportados

| Sitio | Dominio |
| --- | --- |
| Fanfiction.net | `fanfiction.net` |
| Archive of Our Own | `archiveofourown.org` |
| Webnovel | `webnovel.com` |
| Royal Road | `royalroad.com` |
| Wikipedia | `wikipedia.org` |
| Substack | `substack.com` |
| Blogger | `blogspot.com` |

Cualquier otro dominio cae al **extractor genérico** (`<article>`, o bloques con clases como `content`, `chapter` o `post`). Lista completa y guía para añadir sitios en [docs/SITIOS.md](docs/SITIOS.md).

## 🛠️ Tecnología

| Componente | Uso |
| --- | --- |
| [mdream](https://github.com/harlan-zw/mdream) (`@mdream/js`, CDN) | Motor de conversión HTML → Markdown |
| HTML + CSS + JavaScript vanilla | Interfaz y lógica, sin frameworks |
| DOMParser + querySelectorAll | Extracción de contenido por sitio |
| FileReader / TextDecoder | Lectura y decodificación de archivos |
| Blob + URL.createObjectURL | Descarga de archivos |

Sin build, sin npm, sin bundler.

## 📚 Documentación

| Documento | Contenido |
| --- | --- |
| [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) | Estructura de carpetas, capas y flujo de procesamiento |
| [docs/SITIOS.md](docs/SITIOS.md) | Sitios soportados y guía para añadir un extractor |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Plan de versiones |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | Cómo contribuir |

## 🗺️ Roadmap

- **v1.0** (actual) — Núcleo de conversión, MHTML, extractores y fallback en cascada.
- **v1.1** — Más extractores (Wattpad, Medium, Scribble Hub…), soporte EPUB, splitter para RAG.
- **v2.0** — Port a Flutter (Android, iOS, Web) con integración nativa.

Detalle completo en [docs/ROADMAP.md](docs/ROADMAP.md).

## 🤝 Contribuir

Las contribuciones son bienvenidas. La más común es **añadir un extractor**: se crea un archivo y se registra, nada más. Lee [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) antes de abrir un PR.

## 📄 Licencia

Distribuido bajo la [Licencia MIT](LICENSE). Puedes usar, modificar y distribuir este software libremente, incluso en proyectos comerciales.
