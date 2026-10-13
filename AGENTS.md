# AGENTS.md

Contexto para agentes de IA (OpenCode, Cursor, Copilot, etc.) que trabajen en este repositorio.

---

## Qué es Vitale

Vitale convierte archivos **HTML y MHTML en Markdown limpio**, 100% local en el dispositivo: sin servidores, sin cuentas, sin telemetría. Pensado para lectura offline, preparación de contenido para LLMs y archivado personal. Licencia MIT.

---

## Dos bases de código

| Ruta | Qué es | Rol |
|---|---|---|
| `prototipe/` | Versión web original (HTML + CSS + JS vanilla, 20 archivos modulares) | **Referencia funcional**. La fuente de verdad del comportamiento. |
| `lib/` | App **Flutter** (Android, iOS, Web) — Clean Architecture | El objetivo: portar la misma funcionalidad. |
| `docs/` | Documentación markdown (SITIOS, ARQUITECTURA, ROADMAP, CONTRIBUTING) | Docs del proyecto. |

> ⚠️ **El prototipo web vive en `prototipe/` en la raíz**, NO en `docs/web/`. Si ves referencias a `docs/web/` en algún lado, están desactualizadas.

---

## Fuente de verdad

- **Arquitectónico** → `Especificación de Arquitectura - Vitale (Flutter).md` (raíz). Manda sobre capas, contratos y estructura. **Leelo antes de escribir código Dart.**
- **Funcional** → el código en `prototipe/`. Manda sobre el comportamiento exacto (selectores, parseo MHTML, orden de carga, textos de UI).

Si hay conflicto: gana el prototipo en lo funcional y la especificación en lo arquitectónico.

---

## Arquitectura del port (Flutter)

**Clean Architecture, 3 capas, feature-first.** Regla de dependencia estricta:

```
Presentation  →  Domain  ←  Data
```

- **Domain**: entidades, interfaces de repositorio y casos de uso. Puro Dart, sin Flutter ni paquetes externos.
- **Data**: implementaciones (datasources, extractores, modelos, plataforma).
- **Presentation**: widgets, páginas y controladores de estado.

`domain` **nunca** importa `data` ni `presentation`.

La estructura de carpetas completa y los contratos del dominio (interfaces y entidades) están en la especificación, secciones §3 y §4. **No inventes la estructura: copiala de ahí.**

- Gestión de estado: **Riverpod** (recomendado) o Bloc — elegí una y sé consistente.
- Estructura esperada: `lib/core/`, `lib/features/convert/{domain,data,presentation}/`, `lib/shared/`, `lib/routes/`.

---

## Cómo añadir soporte para un sitio nuevo

Regla de extensibilidad: **un archivo nuevo + registrarlo. Nada más.**

1. En el port Flutter: crear `lib/features/convert/data/extractors/<sitio>_extractor.dart`.
2. Registrarlo en `ExtractorRegistryImpl`.
3. No se toca ningún otro archivo.

El sistema detecta el sitio desde la URL del MHTML, aplica el extractor y cae al genérico si falla (fallback en cascada). Guía completa en `docs/SITIOS.md`.

---

## Estado actual (2026-10-13)

- `lib/main.dart` es **todavía la plantilla default** de Flutter (contador). No hay código real de la app aún.
- `pubspec.yaml` solo tiene `cupertino_icons` + `flutter_lints`. Las dependencias de la especificación (`file_picker`, `path_provider`, `share_plus`, `html`, `html_unescape`, `flutter_riverpod`, `web` + motor HTML→MD) **todavía no están instaladas**.
- El motor de conversión del prototipo es **mdream** (Rust/WASM). Para Flutter, la spec §5.3 recomienda un paquete Dart puro (ej. `html2md` o `turndown_dart`).

Antes de añadir una dependencia que no esté en la lista de la spec, **listala y pedí confirmación**.

---

## Convenciones de código

1. **Archivos**: `snake_case.dart`. Un archivo = una responsabilidad.
2. **Clases**: `PascalCase`. Casos de uso en infinitivo: `ConvertHtmlToMarkdown`.
3. **Variables/métodos**: `camelCase`. Privados con `_`.
4. **Imports**: agrupados `dart:` → `package:` → relativos, separados por línea en blanco.
5. **Errores**: usar `sealed class` para estados; `throw` solo para errores de programación.
6. **Docstrings** `///` en toda clase y método público.
7. **Linter**: `flutter_lints` + reglas estrictas. `flutter analyze` sin warnings.

---

## Comandos

```bash
# App Flutter
flutter pub get
flutter analyze            # debe salir limpio
flutter test               # tests unitarios y de widget
flutter run -d chrome      # Web
flutter run -d android
flutter run -d ios

# Prototipo web (referencia funcional)
cd prototipe
python -m http.server 8000   # http://localhost:8000/
```

---

## Gotchas

- **`prototipe/`**, no `docs/web/`.
- Los `.md` descargados llevan **BOM UTF-8** (`0xEF 0xBB 0xBF`) para que los acentos se vean bien en cualquier visor.
- El prototipo comparte namespace global `window.Vitale`; el **orden de carga** de los `<script>` importa.
- El flujo de conversión completo (MHTML → HTML → extractor → Markdown) está diagramado en `docs/ARQUITECTURA.md`.
- La descarga de URLs es **manual-asistida** a propósito (los navegadores bloquean CORS desde local; además hace a la app inmune a anti-bots como Cloudflare).
