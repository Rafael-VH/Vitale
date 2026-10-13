# Especificación de Arquitectura: Vitale (Flutter)

**Documento para agentes de IA (OpenCode) y desarrolladores.**

Este documento define la **arquitectura limpia (Clean Architecture)** y la **modularización** que debe seguir la implementación de la aplicación **Vitale** en Flutter. El proyecto Flutter ya ha sido inicializado por el desarrollador. El trabajo del agente consiste en **escribir el código fuente dentro de la estructura aquí definida**, respetando las capas, responsabilidades y contratos.

**Plataformas objetivo: Android, iOS y Web.**

---

## 0. Estructura del Repositorio

El repositorio en GitHub tiene esta disposición:

```
vitale/
├── docs/
│   ├── SITIOS.md                    # Documentación de sitios soportados
│   ├── ARQUITECTURA.md              # Arquitectura de la versión web
│   ├── ROADMAP.md                   # Roadmap del proyecto
│   └── CONTRIBUTING.md              # Guía de contribución
├── prototipe/                       # Versión web original (referencia funcional)
│   ├── index.html
│   ├── styles.css
│   └── js/
│       ├── core/                    # utils.js, mhtml-parser.js, charset.js
│       ├── extractors/              # registry, base + un archivo por sitio
│       ├── platform.js
│       ├── site-detector.js
│       ├── mdream-loader.js
│       ├── download-modal.js
│       ├── convert-panel.js
│       ├── assist-panel.js
│       └── main.js
├── lib/                             # Código Dart de la app Flutter
├── test/                            # Tests de la app Flutter
├── android/                         # Proyecto Android
├── ios/                             # Proyecto iOS
├── web/                             # Proyecto web de Flutter
├── pubspec.yaml                     # Dependencias del proyecto Flutter
├── analysis_options.yaml            # Reglas de linting
├── README.md                        # README principal del repositorio
├── LICENSE
└── AGENTS.md                        # Contexto para agentes de IA
```

**Nota para el agente**: cuando este documento mencione "`index.html`" como referencia funcional, se refiere a **`prototipe/index.html`** y sus archivos JS asociados en **`prototipe/js/`**. Todas las rutas de código (`lib/...`) son relativas a la **raíz del repositorio**.

---

## 1. Objetivo del Proyecto

**Vitale** convierte archivos HTML y MHTML en Markdown limpio, de forma local y sin servidores. La versión web original vive en `prototipe/` y sirve como **referencia funcional completa**. La versión web ya está **modularizada** en 20 archivos JavaScript organizados en capas.

El objetivo del port a Flutter es ofrecer la misma funcionalidad en **Android, iOS y Web**, con:
- Rendimiento nativo al procesar archivos MHTML grandes (Android, iOS).
- Integración con el sistema de archivos y el menú de compartir del SO (Android, iOS).
- Uso de la File System Access API o descarga directa (Web).
- **Sistema de extractores por sitio** con auto-registro y detección automática del dominio.
- Código modular, testeable y mantenible.

---

## 2. Principios Arquitectónicos

La aplicación sigue **Clean Architecture** con **3 capas** y **feature-first** para el módulo principal:

```
Presentation  →  Domain  ←  Data
```

- **Domain**: reglas de negocio puras, sin dependencias de Flutter ni de paquetes externos. Contiene entidades, casos de uso e interfaces de repositorio.
- **Data**: implementaciones concretas de los repositorios del dominio. Aquí viven las dependencias externas (paquetes `file_picker`, `share_plus`, `path_provider`, `html`, etc.).
- **Presentation**: widgets, pantallas, controladores de estado (Riverpod o Bloc). No conoce implementaciones concretas, solo interfaces del dominio.

**Regla de dependencia estricta**: `Presentation → Domain ← Data`. Nunca al revés. El dominio no conoce a nadie.

### Principios heredados de la versión web

- **Un archivo = una responsabilidad**: cada archivo hace una cosa y la hace bien.
- **Extensibilidad por sitio**: añadir un sitio nuevo = crear un archivo, no modificar los existentes.
- **Fallback en cascada**: si un extractor específico falla, se cae al genérico sin romper la conversión.
- **Sin dependencias innecesarias**: se prefiere código propio a paquetes que hacen demasiado.

---

## 3. Estructura de Carpetas

El agente debe crear y respetar exactamente esta estructura dentro de `lib/`:

```
lib/
├── main.dart                                   # Punto de entrada, bootstrap de Riverpod
├── app.dart                                    # MaterialApp, tema, rutas raíz
│
├── core/                                       # Utilidades transversales
│   ├── constants/
│   │   ├── app_constants.dart                  # Nombres, versiones, rutas
│   │   └── supported_formats.dart              # Extensiones y MIME types soportados
│   ├── errors/
│   │   ├── failures.dart                       # Jerarquía de fallos del dominio
│   │   └── exceptions.dart                     # Excepciones de la capa Data
│   ├── theme/
│   │   ├── app_theme.dart                      # Tema oscuro principal
│   │   ├── app_colors.dart                     # Paleta de colores
│   │   └── app_typography.dart                 # Tipografías y escalas
│   ├── utils/
│   │   ├── charset_detector.dart               # Detección de charset desde <meta>
│   │   ├── utf8_bom.dart                       # Prepend BOM UTF-8 a bytes
│   │   ├── filename_sanitizer.dart             # Limpieza de nombres de archivo
│   │   └── quoted_printable_decoder.dart       # Decodificador de quoted-printable
│   └── extensions/
│       └── string_extensions.dart              # Helpers de string
│
├── features/
│   └── convert/                                # Feature principal de conversión
│       │
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── source_input.dart           # Input: archivo o texto pegado
│       │   │   ├── conversion_result.dart      # Output: markdown + metadatos
│       │   │   ├── mhtml_document.dart         # Representación de MHTML parseado
│       │   │   ├── site_key.dart               # Identificador del sitio detectado
│       │   │   └── extractor_config.dart       # Configuración de un extractor
│       │   ├── repositories/
│       │   │   ├── conversion_repository.dart  # Interfaz: HTML → Markdown
│       │   │   ├── file_repository.dart        # Interfaz: leer/escribir archivos
│       │   │   ├── clipboard_repository.dart   # Interfaz: portapapeles
│       │   │   └── extractor_repository.dart   # Interfaz: registro de extractores
│       │   └── usecases/
│       │       ├── convert_html_to_markdown.dart
│       │       ├── extract_html_from_mhtml.dart
│       │       ├── extract_main_content.dart
│       │       ├── detect_site_from_url.dart
│       │       ├── load_file_as_text.dart
│       │       ├── save_markdown_file.dart
│       │       └── share_markdown_file.dart
│       │
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── mhtml_parser_datasource.dart       # Parsing crudo de MHTML
│       │   │   ├── markdown_engine_datasource.dart    # Wrapper del motor
│       │   │   └── site_detector_datasource.dart      # Extrae URL del MHTML
│       │   ├── extractors/                            # Un archivo por sitio
│       │   │   ├── extractor.dart                     # Clase base de extractores
│       │   │   ├── extractor_registry.dart            # Registro central
│       │   │   ├── generic_extractor.dart             # Fallback genérico
│       │   │   ├── fanfiction_extractor.dart
│       │   │   ├── ao3_extractor.dart
│       │   │   ├── webnovel_extractor.dart
│       │   │   ├── royalroad_extractor.dart
│       │   │   ├── wikipedia_extractor.dart
│       │   │   ├── substack_extractor.dart
│       │   │   └── blogger_extractor.dart
│       │   ├── models/
│       │   │   ├── conversion_result_model.dart       # Extiende entity
│       │   │   └── mhtml_document_model.dart          # Extiende entity
│       │   ├── platform/
│       │   │   ├── file_repository_mobile.dart        # Android + iOS
│       │   │   └── file_repository_web.dart           # Web
│       │   └── repositories/
│       │       ├── conversion_repository_impl.dart
│       │       ├── extractor_repository_impl.dart
│       │       ├── file_repository_impl.dart          # Delegador mobile/web
│       │       └── clipboard_repository_impl.dart
│       │
│       └── presentation/
│           ├── controllers/
│           │   ├── convert_controller.dart            # Estado: idle, loading, success, error
│           │   └── download_controller.dart           # Estado del modal de descarga
│           ├── pages/
│           │   └── convert_page.dart                  # Pantalla principal
│           └── widgets/
│               ├── upload_card.dart                   # Panel de carga con drag & drop
│               ├── input_preview.dart                 # Textarea de HTML
│               ├── output_preview.dart                # Visualizador de Markdown
│               ├── action_buttons.dart                # Botones Convertir / Descargar
│               ├── download_dialog.dart               # Modal de nombre de archivo
│               ├── status_banner.dart                 # Barra de estado superior
│               ├── site_badge.dart                    # Pill del sitio detectado
│               └── platform_instructions.dart         # Pasos para Android / iOS / Web
│
├── shared/                                     # Recursos compartidos entre features
│   ├── widgets/
│   │   ├── primary_button.dart
│   │   ├── secondary_button.dart
│   │   └── app_brand.dart                      # Marca "Vitale" con logo
│   └── providers/
│       └── platform_provider.dart              # Detección de Android / iOS / Web
│
└── routes/
    └── app_router.dart                         # Rutas nombradas (si se requieren varias pantallas)
```

**Regla**: ninguna capa importa archivos de una capa superior. `domain` no puede importar `data` ni `presentation`.

**Regla de extensibilidad**: para añadir soporte a un sitio nuevo, solo se debe:
1. Crear un archivo `lib/features/convert/data/extractors/<sitio>_extractor.dart`.
2. Registrarlo en el `ExtractorRegistryImpl`.
3. Nada más. El resto del sistema lo detecta automáticamente.

---

## 4. Contratos del Dominio

A continuación se definen las **interfaces y entidades** que el agente debe implementar primero. Estas son la base del contrato entre capas.

### 4.1. Entidades básicas

```dart
// lib/features/convert/domain/entities/source_input.dart
sealed class SourceInput {
  const SourceInput();
}

class FileInput extends SourceInput {
  final String path;
  final String filename;
  final List<int> bytes;
  const FileInput({required this.path, required this.filename, required this.bytes});
}

class PastedInput extends SourceInput {
  final String text;
  const PastedInput(this.text);
}
```

```dart
// lib/features/convert/domain/entities/conversion_result.dart
class ConversionResult {
  final String markdown;
  final int originalLength;
  final int markdownLength;
  final bool wasMhtml;
  final bool wasFiltered;
  final int? mhtmlParts;
  final String? filterInfo;
  final SiteKey siteKey;
  final String? originUrl;
  final ExtractionMethod method;

  const ConversionResult({
    required this.markdown,
    required this.originalLength,
    required this.markdownLength,
    required this.wasMhtml,
    required this.wasFiltered,
    this.mhtmlParts,
    this.filterInfo,
    this.siteKey = SiteKey.unknown,
    this.originUrl,
    this.method = ExtractionMethod.none,
  });

  double get reductionPercent =>
      originalLength > 0 ? (100 - markdownLength / originalLength * 100) : 0;
}
```

### 4.2. Entidades de extractores

```dart
// lib/features/convert/domain/entities/site_key.dart
enum SiteKey {
  fanfiction,
  ao3,
  webnovel,
  royalroad,
  wikipedia,
  substack,
  blogger,
  unknown;

  String get label => switch (this) {
    SiteKey.fanfiction => 'Fanfiction',
    SiteKey.ao3        => 'AO3',
    SiteKey.webnovel   => 'Webnovel',
    SiteKey.royalroad  => 'Royal Road',
    SiteKey.wikipedia  => 'Wikipedia',
    SiteKey.substack   => 'Substack',
    SiteKey.blogger    => 'Blogger',
    SiteKey.unknown    => 'Desconocido',
  };

  String get key => name;
}
```

```dart
// lib/features/convert/domain/entities/extractor_config.dart
enum ExtractionMethod {
  siteSelector,
  siteCustom,
  generic,
  none,
}

class ExtractorConfig {
  final SiteKey siteKey;
  final List<String> domains;
  final List<String> selectors;
  final String Function(String html)? customExtractor;

  const ExtractorConfig({
    required this.siteKey,
    required this.domains,
    this.selectors = const [],
    this.customExtractor,
  });
}
```

### 4.3. Interfaz del repositorio principal

```dart
// lib/features/convert/domain/repositories/conversion_repository.dart
abstract class ConversionRepository {
  Future<ConversionResult> convert(SourceInput input);
  String? extractHtmlFromMhtml(String raw);
  PreparedHtml prepareHtml(String rawInput);
}

class PreparedHtml {
  final String html;
  final bool wasMhtml;
  final bool wasFiltered;
  final int? mhtmlParts;
  final SiteKey siteKey;
  final String? originUrl;
  final ExtractionMethod method;
  final String? info;
  const PreparedHtml({
    required this.html,
    required this.wasMhtml,
    required this.wasFiltered,
    required this.siteKey,
    required this.method,
    this.mhtmlParts,
    this.originUrl,
    this.info,
  });
}
```

### 4.4. Interfaz del registro de extractores

```dart
// lib/features/convert/domain/repositories/extractor_repository.dart
abstract class ExtractorRepository {
  void register(ExtractorConfig config);
  ExtractorConfig? get(SiteKey siteKey);
  List<SiteKey> listSupportedSites();
  SiteKey detectFromUrl(String? url);
  ExtractedContent extractMainContent(String html, SiteKey siteKey);
}

class ExtractedContent {
  final String html;
  final ExtractionMethod method;
  const ExtractedContent({required this.html, required this.method});
}
```

### 4.5. Interfaz del repositorio de archivos

```dart
// lib/features/convert/domain/repositories/file_repository.dart
abstract class FileRepository {
  Future<SourceInput?> pickFile();
  Future<String> saveMarkdown({
    required String filename,
    required String markdown,
  });
  Future<void> shareMarkdown({
    required String filename,
    required String markdown,
  });
}
```

### 4.6. Casos de uso

```dart
// lib/features/convert/domain/usecases/convert_html_to_markdown.dart
class ConvertHtmlToMarkdown {
  final ConversionRepository repository;
  ConvertHtmlToMarkdown(this.repository);

  Future<ConversionResult> call(SourceInput input) => repository.convert(input);
}
```

Los demás casos de uso siguen el mismo patrón:
- `ExtractHtmlFromMhtml` → envuelve `extractHtmlFromMhtml`
- `ExtractMainContent` → usa `ExtractorRepository.extractMainContent`
- `DetectSiteFromUrl` → usa `ExtractorRepository.detectFromUrl`
- `LoadFileAsText` → usa `FileRepository.pickFile()`
- `SaveMarkdownFile` → usa `FileRepository.saveMarkdown()`
- `ShareMarkdownFile` → usa `FileRepository.shareMarkdown()`

---

## 5. Implementación de la Capa Data

El agente debe implementar aquí toda la lógica que en `prototipe/js/` está en JavaScript. Los **nombres de las funciones y su comportamiento** se mantienen para facilitar la trazabilidad con el original.

### 5.1. `MhtmlParserDataSource`

Puerto directo de `prototipe/js/core/mhtml-parser.js`. Detalles importantes:

- Detectar cabecera `Content-Type: multipart/related` y `boundary=`.
- Si no hay boundary, buscar el primer `<!DOCTYPE html` o `<html>`.
- Dividir por `--<boundary>`.
- Para cada parte, leer cabeceras hasta el doble salto de línea (`\r\n\r\n` o `\n\n`).
- Filtrar por `Content-Type: text/html`.
- Decodificar según `Content-Transfer-Encoding`:
  - `base64` → `dart:convert` con `base64Decode`.
  - `quoted-printable` → usar `QuotedPrintableDecoder` (ver §5.4).
  - Otro o ausente → tratar como texto plano.
- Devolver la parte HTML **más grande** encontrada.
- Eliminar cualquier residuo del boundary al final del HTML.

Método público:

```dart
MhtmlExtractionResult? extract(String mhtml);

class MhtmlExtractionResult {
  final String html;
  final int parts;
  final int htmlPartsFound;
}
```

### 5.2. `SiteDetectorDataSource`

Puerto de `prototipe/js/site-detector.js`. Extrae la URL original del MHTML probando en orden:

1. Cabecera `Snapshot-Content-Location` (Chrome, Edge, Brave, Vivaldi).
2. Cabecera `Content-Location` que sea `http`/`https`.
3. `<link rel="canonical" href="...">` dentro del HTML.
4. `<meta property="og:url" content="...">` dentro del HTML.

Método público:

```dart
String? extractOriginUrl(String mhtml);
```

### 5.3. `MarkdownEngineDataSource`

Envolver el motor de conversión. **Decisión técnica pendiente**: el motor original es `mdream` (Rust/WASM). En Flutter hay tres caminos:

- **Opción A — Paquete Dart equivalente**: buscar en `pub.dev` un conversor HTML→Markdown maduro (por ejemplo `html2md` o `turndown_dart`). Es la opción más limpia y funciona en Android, iOS y Web.
- **Opción B — Ejecutar mdream vía JS (solo Web)**: en Web se puede cargar el bundle de mdream directamente. En móvil esto requiere `flutter_js`, que añade complejidad.
- **Opción C — Implementar conversor propio**: sólo si las dos anteriores fallan.

**Recomendación**: usar un paquete Dart puro (Opción A) porque funciona en las tres plataformas objetivo sin código condicional.

Interfaz pública:

```dart
abstract class MarkdownEngine {
  String convert(String html);
}
```

Sin importar la opción elegida, el resto del sistema no debe saber cuál se usa.

### 5.4. `QuotedPrintableDecoder`

Puerto de `decodeQuotedPrintable` del JS. Dart no incluye decoder nativo.

```dart
class QuotedPrintableDecoder {
  /// Decodifica una cadena quoted-printable a texto UTF-8.
  ///
  /// Acumula los bytes y los decodifica como UTF-8 de una sola pasada
  /// para preservar los caracteres multi-byte (acentos, ñ, etc.).
  static String decode(String input) {
    final cleaned = input.replaceAll(RegExp(r'=\r?\n'), '');
    final bytes = <int>[];

    for (var i = 0; i < cleaned.length; i++) {
      if (cleaned[i] == '=' && i + 2 < cleaned.length) {
        final hex = cleaned.substring(i + 1, i + 3);
        final value = int.tryParse(hex, radix: 16);
        if (value != null) {
          bytes.add(value);
          i += 2;
          continue;
        }
      }
      bytes.add(cleaned.codeUnitAt(i) & 0xFF);
    }

    return utf8.decode(bytes, allowMalformed: true);
  }
}
```

### 5.5. Extractores por sitio

Cada extractor es una clase que implementa la interfaz `Extractor`:

```dart
// lib/features/convert/data/extractors/extractor.dart
abstract class Extractor {
  SiteKey get siteKey;
  List<String> get domains;
  List<String> get selectors;
  String? customExtract(String html) => null;

  String? extract(String html);
}
```

El `Extractor` base proporciona una implementación por defecto de `extract` que:

1. Prueba los `selectors` en orden con un parser HTML (paquete `html`).
2. Concatena los resultados de todos los elementos que coincidan.
3. Si el texto total supera los 200 caracteres, devuelve el resultado.
4. Si ningún selector funciona, llama a `customExtract(html)`.
5. Si devuelve null, el flujo cae al extractor genérico.

**Extractores a portar** (uno por archivo, espejo de `prototipe/js/extractors/`):

| Archivo | SiteKey | Dominios | Selectores |
|---|---|---|---|
| `fanfiction_extractor.dart` | `fanfiction` | `fanfiction.net`, `m.fanfiction.net` | `#storycontent` + custom regex |
| `ao3_extractor.dart` | `ao3` | `archiveofourown.org` | `#chapters .userstuff.module`, `#chapters .userstuff`, `#workskin .userstuff.module`, `.userstuff.module`, `.userstuff` |
| `webnovel_extractor.dart` | `webnovel` | `webnovel.com` | `.cha-content`, `.cha-words`, `#chapter-content`, `.chapter-content` |
| `royalroad_extractor.dart` | `royalroad` | `royalroad.com` | `.chapter-content`, `.chapter-inner` |
| `wikipedia_extractor.dart` | `wikipedia` | `wikipedia.org` | `#mw-content-text .mw-parser-output`, `#mw-content-text` |
| `substack_extractor.dart` | `substack` | `substack.com` | `.body.markup`, `.available-content .body` |
| `blogger_extractor.dart` | `blogger` | `blogspot.com` | `.post-body.entry-content`, `.post-body` |

Cada extractor se registra en el `ExtractorRegistryImpl` en su método `registerAll()`.

### 5.6. `ExtractorRegistryImpl`

Puerto de `prototipe/js/extractors/registry.js` y `base.js`. Mantiene un `Map<SiteKey, Extractor>`.

```dart
class ExtractorRegistryImpl implements ExtractorRepository {
  final Map<SiteKey, Extractor> _registry = {};

  @override
  void register(ExtractorConfig config) { /* ... */ }

  @override
  ExtractorConfig? get(SiteKey siteKey) { /* ... */ }

  @override
  List<SiteKey> listSupportedSites() => _registry.keys.toList();

  @override
  SiteKey detectFromUrl(String? url) {
    if (url == null) return SiteKey.unknown;
    try {
      final host = Uri.parse(url).host.toLowerCase();
      for (final extractor in _registry.values) {
        for (final domain in extractor.domains) {
          if (host == domain || host.endsWith('.$domain')) {
            return extractor.siteKey;
          }
        }
      }
    } catch (_) {}
    return SiteKey.unknown;
  }

  @override
  ExtractedContent extractMainContent(String html, SiteKey siteKey) {
    final extractor = _registry[siteKey];
    if (extractor != null) {
      final result = extractor.extract(html);
      if (result != null) {
        return ExtractedContent(html: result, method: ExtractionMethod.siteSelector);
      }
    }

    final generic = GenericExtractor().extract(html);
    if (generic != null && generic.length < html.length) {
      return ExtractedContent(html: generic, method: ExtractionMethod.generic);
    }

    return ExtractedContent(html: html, method: ExtractionMethod.none);
  }
}
```

### 5.7. `GenericExtractor`

Puerto de `extractGeneric` del JS. Prueba patrones amplios con regex sobre cualquier HTML:

1. Buscar `<article>` o `<div>` con `class` o `id` que contenga `story`, `chapter`, `post`, `article` o `content`, con más de 500 caracteres.
2. Si encuentra, devolver solo el interior.
3. Si no, devolver el HTML original.

### 5.8. `ConversionRepositoryImpl`

Orquesta el flujo completo:

```
SourceInput
  ↓ (si es FileInput)
CharsetDetector.readFileSmart() → decodifica el archivo
  ↓
MhtmlParserDataSource.extract() → si es MHTML, extrae el HTML
  ↓
SiteDetectorDataSource.extractOriginUrl() → obtiene la URL
  ↓
ExtractorRegistryImpl.detectFromUrl() → devuelve SiteKey
  ↓
ExtractorRegistryImpl.extractMainContent() → aplica el extractor
  ↓
MarkdownEngineDataSource.convert() → convierte a Markdown
  ↓
ConversionResult (con siteKey, method, originUrl incluidos)
```

Manejo de errores: lanzar `Failure` específicos (`MhtmlParseFailure`, `EmptyInputFailure`, `ConversionFailure`, `UnsupportedFormatFailure`) que la capa de presentación pueda traducir a mensajes.

### 5.9. `FileRepository` — Implementaciones por plataforma

Debido a que las APIs de archivos difieren radicalmente entre móvil y web, el repositorio se divide en dos implementaciones concretas y un delegador.

#### 5.9.1. `FileRepositoryMobile` (Android + iOS)

- `pickFile`: usar `file_picker` con filtros de extensión.
- `saveMarkdown`: 
  1. Obtener directorio destino con `path_provider`. Usar `getApplicationDocumentsDirectory()` en iOS y `getDownloadsDirectory()` o `getExternalStorageDirectory()` en Android.
  2. **Prepend BOM UTF-8** al contenido (bytes `[0xEF, 0xBB, 0xBF]`).
  3. Escribir bytes con `File.writeAsBytes`.
- `shareMarkdown`: usar `share_plus` con `ShareParams(files: [XFile(path)])`.

#### 5.9.2. `FileRepositoryWeb`

- `pickFile`: usar `file_picker` (que ya soporta web). Alternativamente usar `package:web` con `HTMLInputElement`.
- `saveMarkdown`: 
  1. Crear el contenido como `List<int>` con BOM.
  2. Usar `package:web` para crear un `Blob` y un `URL.createObjectURL`.
  3. Crear un `<a>` con `download = filename` y disparar `click()`.
  4. Liberar el objeto URL con `URL.revokeObjectURL`.
- `shareMarkdown`: en web **no existe diálogo nativo de compartir**. La mejor opción es la **Web Share API** (`navigator.share`) si está disponible, con fallback a la descarga directa.

#### 5.9.3. `FileRepositoryImpl` (delegador)

```dart
class FileRepositoryImpl implements FileRepository {
  final FileRepositoryMobile _mobile;
  final FileRepositoryWeb _web;
  FileRepositoryImpl(this._mobile, this._web);

  FileRepository get _delegate => kIsWeb ? _web : _mobile;

  @override
  Future<SourceInput?> pickFile() => _delegate.pickFile();

  @override
  Future<String> saveMarkdown({required String filename, required String markdown}) =>
      _delegate.saveMarkdown(filename: filename, markdown: markdown);

  @override
  Future<void> shareMarkdown({required String filename, required String markdown}) =>
      _delegate.shareMarkdown(filename: filename, markdown: markdown);
}
```

Registrar este delegador como `Provider<FileRepository>` en el bootstrap de Riverpod.

### 5.10. `ClipboardRepositoryImpl`

Usar `Clipboard.getData` y `Clipboard.setData` de `services.dart`. Funciona sin cambios en Android, iOS y Web.

---

## 6. Capa de Presentación

### 6.1. Gestión de estado

**Riverpod** (versión 2 o superior) es la opción recomendada. Alternativa: Bloc. El agente debe elegir una y ser consistente.

```dart
// lib/features/convert/presentation/controllers/convert_controller.dart
sealed class ConvertState {
  const ConvertState();
}
class ConvertIdle extends ConvertState { const ConvertIdle(); }
class ConvertLoading extends ConvertState { const ConvertLoading(); }
class ConvertSuccess extends ConvertState {
  final ConversionResult result;
  const ConvertSuccess(this.result);
}
class ConvertFailure extends ConvertState {
  final String message;
  const ConvertFailure(this.message);
}
```

El controlador expone métodos: `convertFromFile()`, `convertFromPasted()`, `clear()`.

El estado incluye el `SiteKey` detectado en `ConvertSuccess`, y la UI lo consume para renderizar el pill del sitio.

### 6.2. Pantallas

**Solo una pantalla principal** en esta primera versión: `ConvertPage`. Si en el futuro se añaden "Ajustes", "Historial" o "Acerca de", se agregarán como páginas separadas bajo `presentation/pages/`.

### 6.3. Widgets

Cada widget de la lista en la sección 3 es un archivo independiente con una única responsabilidad. El agente debe extraer la lógica de UI del `index.html` respetando:

- **`upload_card.dart`**: replica el panel de carga con drag & drop. Estados: idle, hover, dragging, loaded.
- **`input_preview.dart`**: textarea con contador de caracteres y botones Pegar/Limpiar.
- **`output_preview.dart`**: `SelectableText` con estilo monoespaciado.
- **`action_buttons.dart`**: dos botones primarios — Convertir y Descargar. El segundo deshabilitado hasta éxito.
- **`download_dialog.dart`**: `showDialog` con `TextField` para el nombre y preview en vivo.
- **`status_banner.dart`**: barra superior con el estado del motor.
- **`site_badge.dart`**: pill violeta que muestra el sitio detectado. Oculto cuando `siteKey == SiteKey.unknown`.
- **`platform_instructions.dart`**: pasos condicionales por plataforma (Android/iOS/Web).

### 6.4. Tema

Portar los colores y estilos del `index.html` a `app_theme.dart` con `ThemeData.dark()`:

- Fondo principal: `#0a0e1a`
- Superficie: `#131a2c`
- Acento primario: `#5eead4` (turquesa)
- Acento secundario: `#818cf8` (índigo)
- Sitio detectado (pill): `#c4b5fd` (violeta)
- Texto: `#eef2f9` / dim: `#8b98b4` / mute: `#5c6884`
- Éxito: `#34d399` — Error: `#f87171` — Warn: `#fbbf24`

Fuentes: `Inter` para UI, `JetBrains Mono` o `Fira Code` para bloques de código y nombres de archivo.

---

## 7. Detección de Plataforma

El `index.html` adapta textos e instrucciones según Android / iOS / Web. Portarlo a:

```dart
// lib/shared/providers/platform_provider.dart
enum PlatformKind { android, ios, web }

PlatformKind detectPlatform() {
  if (kIsWeb) return PlatformKind.web;
  if (Platform.isAndroid) return PlatformKind.android;
  if (Platform.isIOS) return PlatformKind.ios;
  throw UnsupportedError('Plataforma no soportada');
}
```

Expuesto como `Provider<PlatformKind>` para que los widgets lo consuman reactivamente.

### Diferencias por plataforma a manejar

| Aspecto | Android | iOS | Web |
|---|---|---|---|
| Selección de archivo | `file_picker` | `file_picker` | `file_picker` (input file) |
| Guardar `.md` | Escribir en disco + notificación | Escribir en Documents | Descarga directa |
| Compartir | `share_plus` | `share_plus` | Web Share API o descarga |

---

## 8. Convenciones de Código

El agente debe seguir estas convenciones para mantener consistencia:

1. **Archivos**: `snake_case.dart`, un archivo = una clase pública principal (con excepciones justificadas).
2. **Clases**: `PascalCase`. Casos de uso son verbos en infinitivo: `ConvertHtmlToMarkdown`, `ExtractMainContent`.
3. **Variables y métodos**: `camelCase`. Privados con `_` prefijo.
4. **Constantes**: `lowerCamelCase` para `const`, `SCREAMING_SNAKE_CASE` para verdaderas constantes globales.
5. **Imports**: agrupar por `dart:`, `package:`, relativos, con línea en blanco entre grupos.
6. **Errores**: usar `Result`/`Either` o el patrón `sealed class` para estados, y `throw` sólo para errores de programación.
7. **Comentarios**: docstrings `///` en todas las clases y métodos públicos. Nada de comentarios obvios.
8. **Linter**: respetar `flutter_lints` + añadir `analysis_options.yaml` con reglas estrictas (`prefer_const_constructors`, `always_declare_return_types`, `avoid_print`, etc.).

### Reglas específicas para extractores

- Un archivo por sitio, nombre `<sitio>_extractor.dart`.
- La clase se llama `<Sitio>Extractor` en PascalCase.
- Debe extender `Extractor` e implementar `siteKey`, `domains`, `selectors`.
- Si necesita lógica custom, sobreescribe `customExtract`.
- No incluye lógica de UI. Solo transforma HTML.

---

## 9. Testing

El agente debe crear tests en paralelo a la implementación:

- **Unit tests de dominio**: casos de uso puros, sin dependencias. Ubicación: `test/features/convert/domain/usecases/`.
- **Unit tests de data**: datasources con fixtures de MHTML y HTML reales. Ubicación: `test/features/convert/data/datasources/`.
- **Unit tests de extractores**: uno por sitio, con un MHTML fixture real. Ubicación: `test/features/convert/data/extractors/`.
- **Widget tests**: pantalla y widgets principales. Ubicación: `test/features/convert/presentation/widgets/`.
- **Golden tests** (opcional): para verificar consistencia visual del tema.

**Fixtures**: crear carpeta `test/fixtures/` con archivos `.mhtml`, `.html` y `.md` de referencia que cubran:

- MHTML válido de Chrome con contenido típico.
- MHTML de Fanfiction.net con `#storycontent`.
- MHTML de AO3 con múltiples capítulos.
- MHTML de Webnovel.
- HTML suelto con contenedor genérico.
- HTML suelto sin contenedor identificable (fallback).
- MHTML con HTML codificado en base64.
- MHTML con HTML codificado en quoted-printable.
- MHTML de un sitio no soportado (para verificar `SiteKey.unknown`).

**Test de ejemplo**:

```dart
// test/features/convert/data/extractors/fanfiction_extractor_test.dart
test('extrae #storycontent de un MHTML de Fanfiction', () {
  final html = File('test/fixtures/fanfiction.mhtml').readAsStringSync();
  final result = FanfictionExtractor().extract(html);
  expect(result, isNotNull);
  expect(result!.length, greaterThan(200));
  expect(result, isNot(contains('<nav')));
  expect(result, isNot(contains('<footer')));
});
```

**Nota**: los tests unitarios y de widget corren en la VM de Dart y no dependen de la plataforma. Los tests que involucren `FileRepositoryWeb` deben marcarse con `@TestOn('browser')` o moverse a `test/web/`.

---

## 10. Orden de Implementación Recomendado

El agente debe implementar en este orden para mantener el proyecto siempre compilable:

1. **Core**: `errors`, `constants`, `utils`, `theme`. Sin dependencias.
2. **Domain**: entidades → interfaces → casos de uso.
3. **Data — Extractores**: `Extractor`, `GenericExtractor`, `ExtractorRegistryImpl`, y cada uno de los 7 extractores específicos.
4. **Data — Datasources**: `MhtmlParserDataSource`, `SiteDetectorDataSource`, `MarkdownEngineDataSource`.
5. **Data — Repositories**: `ConversionRepositoryImpl`, `ExtractorRepositoryImpl`, `FileRepositoryMobile`, `FileRepositoryWeb`, delegador.
6. **Presentation**: controladores → widgets → página.
7. **Bootstrap**: `main.dart` y `app.dart` uniendo todo.
8. **Tests** en paralelo desde el paso 2.

---

## 11. Dependencias Externas Esperadas

El agente puede asumir que el `pubspec.yaml` del proyecto ya contiene (o debe proponer añadir) estas dependencias:

- `file_picker` — selección de archivos (soporta Android, iOS y Web)
- `path_provider` — directorios del sistema (solo móvil)
- `share_plus` — compartir archivos (solo móvil)
- `html` — parseo de HTML y selectores CSS
- `html_unescape` — decodificar entidades HTML
- `flutter_riverpod` (o `flutter_bloc`) — gestión de estado
- `web` — para APIs del navegador (solo en compilación web)
- **Motor de conversión**: elegir según lo indicado en §5.3

Si falta alguna, el agente debe **listarla explícitamente en su respuesta antes de usarla** y esperar confirmación del desarrollador.

**Nota sobre dependencias específicas de plataforma**: `path_provider` y `share_plus` deben declararse como dependencias opcionales en la lógica, y su uso debe estar detrás del delegador `FileRepositoryImpl`, nunca llamado directamente desde la capa de presentación ni del dominio.

---

## 12. Referencia Funcional

La **fuente de verdad funcional** es el conjunto de archivos en `prototipe/`. El agente debe consultarlos para:

- **`prototipe/js/core/mhtml-parser.js`** → comportamiento exacto del parser MHTML (§5.1).
- **`prototipe/js/core/charset.js`** → detección de charset (§5.8).
- **`prototipe/js/core/utils.js`** → funciones de descarga, portapapeles y BOM UTF-8.
- **`prototipe/js/site-detector.js`** → extracción de URL original y `prepareHTML` (§5.2).
- **`prototipe/js/extractors/registry.js`** → comportamiento del registro (§5.6).
- **`prototipe/js/extractors/base.js`** → lógica de extracción por selectores y fallback (§5.7).
- **`prototipe/js/extractors/<sitio>.js`** → selectores exactos por sitio (§5.5).
- **`prototipe/js/convert-panel.js`** → flujo completo del tab principal (§6.3).
- **`prototipe/js/assist-panel.js`** → flujo del asistente de URLs.
- **`prototipe/js/download-modal.js`** → comportamiento del modal de descarga.
- **`prototipe/js/platform.js`** → textos e instrucciones por plataforma (§7).
- **`prototipe/js/main.js`** → orden de inicialización.
- **`prototipe/index.html`** → estructura HTML, IDs de elementos, orden de carga.
- **`prototipe/styles.css`** → colores, espaciados, jerarquía visual del tema (§6.4).

Cuando exista ambigüedad entre esta especificación y la versión web, **prevalece la versión web** en lo funcional, y esta especificación en lo arquitectónico.

---

## 13. Criterios de Aceptación

Se considera la migración completada cuando:

### Funcionalidad

- [ ] Todas las funciones de `prototipe/` están disponibles en Android, iOS y Web.
- [ ] La conversión de un MHTML de Fanfiction produce el mismo Markdown que la versión web.
- [ ] Los archivos `.md` descargados respetan el BOM UTF-8 y muestran acentos correctos en cualquier visor.
- [ ] En Web, la descarga del `.md` funciona en Chrome, Firefox y Safari.
- [ ] En Android, el archivo se comparte correctamente vía `share_plus`.
- [ ] En iOS, el archivo se puede guardar en Files o compartir vía el menú del sistema.

### Sistema de extractores

- [ ] Existe un archivo por sitio en `data/extractors/` para los 7 sitios soportados.
- [ ] El registry detecta correctamente el `SiteKey` a partir de la URL del MHTML.
- [ ] El pill violeta muestra el sitio detectado en la UI.
- [ ] Cuando el sitio no está soportado, el pill se oculta y se usa el genérico sin romper.
- [ ] Añadir un sitio nuevo solo requiere crear un archivo y registrarlo (sin tocar el resto).
- [ ] El fallback en cascada funciona: extractor específico → genérico → HTML completo.

### Calidad

- [ ] Existen tests unitarios para los casos de uso del dominio.
- [ ] Existen tests para los datasources con fixtures reales.
- [ ] Existen tests para cada extractor específico.
- [ ] El análisis estático (`flutter analyze`) no reporta warnings.
- [ ] La app compila y corre sin errores en `flutter run -d chrome`, `flutter run -d android` y `flutter run -d ios`.

### Extensibilidad

- [ ] Un desarrollador nuevo puede añadir un extractor para un sitio nuevo siguiendo solo `docs/SITIOS.md` y `docs/ARQUITECTURA.md`.
- [ ] La estructura de carpetas coincide con la definida en la sección 3.
- [ ] Los principios arquitectónicos de la sección 2 se respetan (Presentation → Domain ← Data).