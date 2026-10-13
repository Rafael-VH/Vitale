# Vitale

**Convierte cualquier HTML o MHTML en Markdown limpio, directamente en el navegador.**

[![License: MIT](https://img.shields.io/badge/License-MIT-5eead4.svg?style=flat-square)](LICENSE)
[![Sin dependencias](https://img.shields.io/badge/dependencias-0-818cf8.svg?style=flat-square)](#)
[![Offline-first](https://img.shields.io/badge/offline--first-sí-34d399.svg?style=flat-square)](#)
[![Optimizado para LLMs](https://img.shields.io/badge/optimizado%20para-LLMs-a78bfa.svg?style=flat-square)](#)

[Demo](#-demo) · [Características](#-características) · [Sitios soportados](docs/SITIOS.md) · [Arquitectura](docs/ARQUITECTURA.md) · [Roadmap](docs/ROADMAP.md) · [Contribuir](docs/CONTRIBUTING.md)

---

## 📖 ¿Qué es Vitale?

**Vitale** es una herramienta web que convierte páginas web guardadas (HTML o MHTML) en archivos Markdown limpios y legibles, **sin instalar nada, sin cuentas, sin servidores**.

Todo el procesamiento ocurre **localmente en tu navegador**. Ningún dato sale de tu dispositivo.

Está pensada para tres casos de uso principales:

1. **Lectura limpia offline** — Guarda un artículo o capítulo web y léelo después como Markdown sin anuncios, menús ni ruido.
2. **Preparación de contenido para LLMs** — Los modelos de lenguaje consumen mucho mejor el Markdown que el HTML. Vitale elimina hasta el 90% de tokens innecesarios.
3. **Archivado personal** — Conserva el contenido textual de páginas que podrían desaparecer, con un formato que sobrevivirá décadas.

---

## ✨ Características principales

### Conversión

- **HTML → Markdown** con [mdream](https://github.com/harlan-zw/mdream), un conversor ultrarrápido escrito en Rust/WASM.
- **Soporte nativo de MHTML/MHT**, el formato que genera Chrome, Edge, Firefox y Safari al usar "Guardar página como".
- **Detección de codificación** — lee el `<meta charset>` del HTML y decodifica correctamente UTF-8, ISO-8859-1, Windows-1252, Shift-JIS, GBK y más.

### Extracción inteligente por sitio

- **Detección automática del sitio de origen** a partir de la URL incrustada en el MHTML.
- **Extractores específicos** para sitios con estructuras conocidas, mucho más precisos que el extractor genérico.
- **Fallback en cascada** — si un extractor específico falla, se cae al genérico sin romper la conversión.
- **Pill visual** en la barra de estado que muestra qué sitio se ha reconocido.

→ [Ver la lista completa de sitios soportados](docs/SITIOS.md)

### Entrada de datos

- **Panel de carga unificado** con drag & drop y selector nativo de archivos.
- **Pegado desde el portapapeles** con un solo botón.
- **Asistente para URLs** que te guía paso a paso para obtener el HTML de una página web.

### Salida

- **Descarga como `.md`** con codificación UTF-8 y BOM, garantizando que los acentos se vean correctamente en cualquier visor.
- **Nombre de archivo editable** — modal que sugiere un nombre y permite cambiarlo antes de guardar.
- **Copiado al portapapeles** para pegar directamente en Obsidian, Notion, VS Code o cualquier editor.

### Diseño y privacidad

- **Interfaz oscura moderna** con microinteracciones y estados visuales claros.
- **Responsive** — funciona igual de bien en móvil que en escritorio.
- **Cero servidores, cero telemetría, cero cuentas.** Todo el procesamiento es local.
- **Funciona offline** después de la primera carga.

---

## 🚀 Demo

**No necesitas clonar nada para probarlo.** Puedes abrirlo de dos formas:

### Opción 1: clonar el repositorio

```bash
git clone https://github.com/tu-usuario/vitale.git
cd vitale
# Abre docs/web/index.html en tu navegador
```

### Opción 2: descargar el ZIP

Ve a la sección **Releases** del repositorio, descarga el ZIP más reciente, descomprímelo y abre `docs/web/index.html` con doble clic.

### Servidor local (recomendado para desarrollo)

Si vas a modificar el código, sirve la carpeta con un servidor local:

```bash
cd docs/web
python -m http.server 8000
# Abre http://localhost:8000/ en tu navegador
```

Funciona en **Chrome, Edge, Firefox, Safari, Brave, Vivaldi, Opera** y cualquier navegador moderno basado en Chromium, Gecko o WebKit.

---

## 📘 Cómo usar

### Convertir un archivo local (HTML o MHTML)

1. **Obtén el archivo HTML/MHTML**:
   - **Escritorio**: abre la página, pulsa `Ctrl+S` y guarda como "Página web, solo HTML" o "Página web, completa".
   - **Android**: abre la página en Chrome → menú `⋮` → **"Descargar página"**. Se guardará como `.mhtml`.
   - **iOS**: abre la página en Safari → botón Compartir → **"Guardar en Archivos"**.
2. **Ábrelo en Vitale**: arrastra el archivo al panel de carga o pulsa el panel y elige el archivo.
3. Pulsa **"Convertir a Markdown"**.
4. Pulsa **"Descargar .md"** y elige el nombre del archivo.

Si el sitio está soportado, verás un pill violeta en la barra de estado indicando el sitio reconocido, y el Markdown resultante contendrá solo el contenido del capítulo.

### Convertir desde una URL

1. Ve a la pestaña **"Obtener de URL"**.
2. Pega la URL y pulsa **"1. Copiar URL"**.
3. Sigue las instrucciones específicas de tu plataforma.
4. Vuelve a la pestaña **"Convertir HTML"** y pega el contenido o arrastra el archivo.

> **Nota sobre CORS**: Vitale no descarga URLs automáticamente. Los navegadores bloquean por seguridad que una página local haga peticiones a dominios externos. Por eso el flujo es manual-asistido, lo cual además lo hace **inmune a protecciones anti-bot como Cloudflare**.

---

## 🛠️ Tecnología

| Componente | Uso |
|---|---|
| [mdream](https://github.com/harlan-zw/mdream) | Motor de conversión HTML → Markdown (Rust/WASM) |
| HTML + CSS + JavaScript vanilla | Interfaz y lógica, sin frameworks |
| DOMParser + querySelectorAll | Extracción de contenido por sitio |
| FileReader / TextDecoder | Lectura y decodificación de archivos |
| Clipboard API + fallback | Pegado y copiado |
| Blob + URL.createObjectURL | Descarga de archivos |

**Sin dependencias de build, sin npm, sin bundler.**

Para conocer la estructura interna del proyecto, consulta [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md).

---

## 📚 Documentación

| Documento | Contenido |
|---|---|
| [docs/SITIOS.md](docs/SITIOS.md) | Lista completa de sitios soportados y guía para añadir nuevos |
| [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) | Estructura de carpetas, capas y flujo de procesamiento |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Roadmap detallado por versiones |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | Cómo contribuir, reportar bugs y añadir extractores |

---

## 📄 Licencia

Distribuido bajo la [Licencia MIT](LICENSE). Puedes usar, modificar y distribuir este software libremente, incluso en proyectos comerciales.

---

## 💬 Créditos

- **mdream** por [harlan-zw](https://github.com/harlan-zw) — el motor que hace posible la conversión.
- **Inspiración** en herramientas como [Pandoc](https://pandoc.org/), [Turndown](https://github.com/mixmark-io/turndown) y [Reader Mode](https://github.com/mozilla/readability).
- **Comunidad** que reporta bugs, propone mejoras y usa Vitale a diario.

---

**Vitale** — *Convierte la web en texto limpio.*