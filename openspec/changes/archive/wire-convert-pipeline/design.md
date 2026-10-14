# Design: Conectar el pipeline de conversión y el estado

> Alineado con `proposal.md` y las deltas `conversion-pipeline` / `conversion-state`. Cambio interno de arquitectura: no añade dependencias ni datos persistentes.

## Technical Approach

Conectar el composition root y cambiar un conjunto mínimo de contratos para que la conversión corra de punta a punta:

1. `SiteDetectorDataSource` (data) extrae el `originUrl` y se inyecta en `ConversionRepositoryImpl`; los dos `null` hardcodeados desaparecen.
2. `ExtractorRegistry.extractContent` devuelve un valor `ExtractOutcome` (domain) en lugar de exponer estado mutable leído después; se elimina `getLastMethod`/`getLastFilterInfo`.
3. `SiteExtractor` expone `SiteKey`; `detectSiteKey` se deriva de los `hostPatterns` registrados.
4. `providers.dart` arma el grafo real (extractores, motores, charset, detector).
5. `ConvertController extends AsyncNotifier<ConversionResult?>` + `home_page.dart` → `ConsumerWidget`.

Los recuadros `throw UnimplementedError()` se eliminan (heredan default de `SiteExtractor`).

## Architecture Decisions

### ADR-1 — `ExtractContent` devuelve `ExtractOutcome` (no estado mutable)

| Opción | Tradeoff | Decisión |
| --- | --- | --- |
| Retorno `ExtractOutcome` inmutable (domain) | Cambia el contrato de dominio y todos los callers | **Elegida** |
| Mantener `getLastMethod()`/`getLastFilterInfo()` | Estado mutable en el registro; propenso a fugas entre conversiones | Rechazada |
| `Record` `(String, ExtractionMethod, String?)` | Sin tipo con nombre; menos legible en docstring público | Rechazada |

**Rationale**: elimina *action-at-a-distance* y satisface `conversion-pipeline` §"Extracción devuelve su resultado" y §"Sin fuga de estado". `ExtractOutcome` vive en **domain** porque es el tipo de retorno de un puerto de dominio; ubicarlo en data filtraría un tipo de data hacia domain (viola la regla de dependencia).

### ADR-2 — `AsyncNotifier<ConversionResult?>` (no `Notifier<ConvertState>` sellado)

| Opción | Tradeoff | Decisión |
| --- | --- | --- |
| `AsyncNotifier<ConversionResult?>`, idle = `AsyncData(null)` | "idle" y "sin dato" comparten representación | **Elegida** |
| `Notifier<ConvertState>` sellado (4 estados, spec §6.1) | +~15 líneas y `switch` manual; explícito | Rechazada por ahora |

**Rationale**: la delta `conversion-state` fija `AsyncNotifier<ConversionResult?>`; `AsyncValue.loading/data/error` cubre los 4 estados sin boilerplate. Nota: diverge del texto de `§6.1` (que propone `Notifier<ConvertState>`); se registra como decisión pendiente de alineación futura (Fase 4).

### ADR-3 — Registrar los motores no disponibles sin filtro de plataforma

| Opción | Tradeoff | Decisión |
| --- | --- | --- |
| Registrar los 3 motores; los stubs reportan `isAvailable == false` | Lista con stubs visibles | **Elegida** |
| Filtrar con `kIsWeb`/`Platform` en `providers.dart` | +import Flutter en presentation; duplica la lógica de `isAvailable` | Rechazada |

**Rationale**: la cascada ya usa `availableEngines` (`isAvailable`), así que registrar stubs es un no-op en comportamiento; mantiene `providers.dart` sin imports de Flutter y permite que un futuro `engine_selector` (§6.3) los liste con su disponibilidad. Cumple §"Registro efectivo de motores".

### ADR-4 — `SiteDetectorDataSource` separado (no dentro de `MhtmlParser`)

| Opción | Tradeoff | Decisión |
| --- | --- | --- |
| Nuevo `data/datasources/site_detector_datasource.dart` | +1 archivo | **Elegida** |
| Añadir `extractOriginUrl` a `MhtmlParser` | Mezcla parsing MIME con heurísticas de URL | Rechazada |

**Rationale**: "un archivo = una responsabilidad" (§2); el nombre y la firma `String? extractOriginUrl(String raw)` están fijados por §3 L148 y §5.2. Funciona tanto para MHTML (cabeceras) como para HTML pegado (canonical/og:url).

### ADR-5 — Sin instanciación oculta en data

`ConversionRepositoryImpl` recibe `mhtmlParser`, `siteDetector` y `charsetDetector` **requeridos**; se eliminan `?? MhtmlParser()` y `?? CharsetDetectorImpl()`. El wiring vive solo en `providers.dart` (regla 12 ArquiMan; §"Inyección de CharsetDetector").

## Data Flow

    SourceInput ─┬─ FileInput  ──> CharsetDetector.decode(bytes)
                 └─ PastedInput ─> text
                                     │
                 MhtmlParser.extractHtml(raw) ──> html (o raw)
                                     │
         SiteDetector.extractOriginUrl(raw) ──> originUrl?
                                     │
   ExtractorRegistry.detectSiteKey(originUrl, html) ──> SiteKey
      ExtractorRegistry.extractContent(html, originUrl) ──> ExtractOutcome{html, method, info}
                                     │
       MarkdownEngineRegistry.convert(html, preferred) ──> EngineOutput
                                     │
                          ConversionResult (originUrl, siteKey, method, filterInfo, engineId)

Presentación: `ConsumerWidget.home_page` ──watch──> `convertControllerProvider` ──> `ConvertController` ──read──> `ConvertHtmlToMarkdown` ──> `ConversionRepository`.

## Interfaces / Contracts

```dart
// lib/features/convert/domain/extractors/extract_outcome.dart  (NUEVO, domain puro)
class ExtractOutcome {
  final String html;
  final ExtractionMethod method;
  final String? info; // siteName del extractor o 'generic'
  const ExtractOutcome({required this.html, required this.method, this.info});
}
```

```dart
// lib/features/convert/domain/extractors/site_extractor.dart  (MODIFICADO)
abstract class SiteExtractor {
  SiteKey get siteKey;              // NUEVO
  String get siteName;
  Set<String> get hostPatterns;
  ExtractionMethod get extractionMethod => ExtractionMethod.siteSelector;
  String extract(String html, {String? originUrl});
}

// lib/features/convert/domain/extractors/extractor_registry.dart  (MODIFICADO)
abstract class ExtractorRegistry {
  SiteKey detectSiteKey(String? originUrl, String html);
  ExtractOutcome extractContent(String html, {String? originUrl}); // era String
  // getLastMethod()/getLastFilterInfo() ELIMINADOS
}
```

`detectSiteKey` antes (mapa fijo) → después (derivado de extractores):

```dart
// ANTES: if-chain hardcodeada sobre 7 dominios
// DESPUÉS:
SiteKey detectSiteKey(String? originUrl, String html) {
  final host = _host(originUrl);
  if (host == null || host.isEmpty) return SiteKey.unknown;
  for (final e in _extractors) {
    if (_matches(host, e.hostPatterns)) return e.siteKey;
  }
  return SiteKey.unknown;
}
```

`extractContent` construye y **devuelve** `ExtractOutcome` en cada rama (match por host → `method: e.extractionMethod, info: e.siteName`; no-op o excepción → `generic`/`'generic'`; sin match → `GenericExtractor`, `generic`/`'generic'`). Corrige el bug actual: la rama de no-op seteaba `method` pero no `info`.

```dart
// lib/features/convert/presentation/controllers/convert_controller.dart  (NUEVO)
class ConvertController extends AsyncNotifier<ConversionResult?> {
  @override
  FutureOr<ConversionResult?> build() => null; // idle = AsyncData(null)

  Future<void> convert(SourceInput input, {EngineId? preferredEngine}) async {
    state = const AsyncValue.loading();
    final r = await ref.read(convertHtmlToMarkdownProvider).call(input, preferredEngine: preferredEngine);
    state = switch (r) {
      Ok(:final value)   => AsyncValue.data(value),
      Err(:final failure) => AsyncValue.error(failure.message, StackTrace.current),
    };
  }
}

final convertControllerProvider =
    AsyncNotifierProvider<ConvertController, ConversionResult?>(ConvertController.new);
```

`convertControllerProvider` vive en `convert_controller.dart` (como en §6.1), no en `providers.dart`: así `providers.dart` (DI raíz) no importa el controller y se evita el ciclo `providers ↔ controller`.

`providers.dart` final:

```dart
final mhtmlParserProvider = Provider<MhtmlParser>((ref) => MhtmlParser());
final siteDetectorProvider = Provider<SiteDetectorDataSource>((ref) => SiteDetectorDataSource());
final charsetDetectorProvider = Provider<CharsetDetector>((ref) => CharsetDetectorImpl());
final enginesProvider = Provider<List<MarkdownEngine>>(
  (ref) => [Html2mdEngine(), MdreamJsEngine(), HtmlToMarkdownRsEngine()]);
final engineRegistryProvider = Provider<MarkdownEngineRegistry>(
  (ref) => MarkdownEngineRegistryImpl(ref.read(enginesProvider)));
final extractorRegistryProvider = Provider<ExtractorRegistry>(
  (ref) => ExtractorRegistryImpl([Ao3Extractor(), FanfictionExtractor()]));
final conversionRepositoryProvider = Provider<ConversionRepository>((ref) => ConversionRepositoryImpl(
  engineRegistry: ref.read(engineRegistryProvider),
  extractorRegistry: ref.read(extractorRegistryProvider),
  mhtmlParser: ref.read(mhtmlParserProvider),
  siteDetector: ref.read(siteDetectorProvider),
  charsetDetector: ref.read(charsetDetectorProvider)));
final convertHtmlToMarkdownProvider = Provider<ConvertHtmlToMarkdown>(
  (ref) => ConvertHtmlToMarkdown(ref.read(conversionRepositoryProvider)));
```

**Ciclo de vida (Riverpod 3.x, sin codegen)**: `autoDispose` NO es default → todos estos providers son *keepAlive*. Se mantiene el default: es el grafo de DI de toda la app y no hay beneficio en re-crearlo. Tras ADR-1 el `ExtractorRegistryImpl` queda **sin estado mutable**, así que el `keepAlive` se elige por semántica de grafo, no para retener estado. `convertControllerProvider` también keepAlive: el resultado debe sobrevivir rebuilds del widget.

### `home_page.dart`

`HomePage extends ConsumerWidget`; se eliminan `_loading/_result/_error` y todo `setState`. `build` hace `final state = ref.watch(convertControllerProvider)` y renderiza con `state.when(loading: CircularProgressIndicator, error: (e,_) => Text('$e', rojo), data: (r) => r == null ? SizedBox.shrink() : vista de resultado)`. Los callbacks usan `ref.read(convertControllerProvider.notifier).convert(input)`. El `TextEditingController` del campo pegado se mueve a un `_PasteField extends StatefulWidget` privado (único widget nuevo; **estrictamente requerido** para disponer el controller). El file-pick mantiene `FilePicker.pickFile(...)` + `readAsBytes()` (API real de `file_picker 13.1.0`); sus excepciones se muestran por `SnackBar`, sin contaminar el estado del controller.

## File Changes

| File | Action | Qué cambia | Δ líneas |
| --- | --- | --- | --- |
| `data/datasources/site_detector_datasource.dart` | Create | `extractOriginUrl`: Snapshot-Content-Location → Content-Location(http/https) → canonical → og:url; `null` si no hay señal | +45 |
| `domain/extractors/extract_outcome.dart` | Create | Value object inmutable | +15 |
| `presentation/controllers/convert_controller.dart` | Create | `ConvertController` + `convertControllerProvider` | +35 |
| `domain/extractors/extractor_registry.dart` | Modify | `extractContent` → `ExtractOutcome`; −2 getters | −2 |
| `domain/extractors/site_extractor.dart` | Modify | +`SiteKey get siteKey` | +1 |
| `data/extractors/extractor_registry_impl.dart` | Modify | `detectSiteKey` derivado; `extractContent` devuelve outcome; sin campos mutables | −18 |
| `data/extractors/ao3_extractor.dart` | Modify | +`siteKey`; −`throw` | 0 |
| `data/extractors/fanfiction_extractor.dart` | Modify | +`siteKey`; −`throw` | 0 |
| `data/extractors/generic_extractor.dart` | Modify | +`siteKey = unknown`; `extractionMethod => generic` | +1 |
| `data/repositories/conversion_repository_impl.dart` | Modify | +`siteDetector` requerido; params requeridos; `originUrl` real; usar `ExtractOutcome` | +12 |
| `presentation/controllers/providers.dart` | Modify | Wiring completo + `charsetDetectorProvider`/`siteDetectorProvider` | +16 |
| `presentation/pages/home_page.dart` | Modify | `ConsumerWidget`, sin `setState` | −20 |

**Total**: 3 nuevos, 9 modificados, 0 eliminados. Fuente ≈ **+130 / −45** (neto ≈ +85). Con los tests nuevos (§Testing) el PR queda ≈ **350–400 líneas** → un solo PR (presupuesto 1000).

## Dependency-rule Validation

Dirección de imports (nada en `domain/` cruza hacia afuera):

```text
presentation ──imports──▶ domain ◀──imports── data
                    ▲
                    └── providers.dart (presentation) importa data + domain (permitido: es el root)
```

- `extract_outcome.dart` (domain) importa solo `conversion_result.dart` (domain).
- `site_extractor.dart` añade `SiteKey` desde `conversion_result.dart` (domain→domain).
- `site_detector_datasource.dart` (data) es Dart puro; no importa `domain`.
- Ningún archivo en `domain/` gana imports hacia `data/`, `presentation/` ni Flutter.
- `convert_controller.dart` (presentation) importa `providers.dart` (presentation) y entidades domain; **no** importa data directamente.

## Testing Strategy

**Impacto en tests existentes**

| Test | Estado | Motivo |
| --- | --- | --- |
| `test/markdown_engine_registry_impl_test.dart` | **No se rompe** | Instancia su propio `MarkdownEngineRegistryImpl([Html2mdEngine()])`; el contrato de motores **no** cambia y no lee `providers.dart`. La colisión de nombre "registry" con el registro de extractores es la única trampa: no conflacionar. |
| `test/html2md_engine_test.dart` | Sin cambios | No toca registry ni providers. |
| `test/result_test.dart` | Sin cambios | Result/Failure intactos. |
| `test/widget_test.dart` | **Debe seguir verde** | Exige `find.text('Vitale')` y `find.textContaining('Pegar HTML')`: la reescritura debe conservar el título del `AppBar` y el hint de pegado. |

Ningún test referencia `getLastMethod`/`getLastFilterInfo` (verificado por grep); su eliminación no rompe tests.

**Tests nuevos esperados** (a escribir en apply/verify, no aquí):

1. `site_detector_datasource_test.dart` — las 4 señales + `null` sin señal.
2. `extractor_registry_impl_test.dart` — `detectSiteKey` desde `hostPatterns`; `ExtractOutcome` con `method`/`info`; fallback no-op → `generic`/`'generic'`; sin fuga entre conversiones.
3. `conversion_repository_impl_test.dart` — `originUrl` propagado; sin defaults ocultos (fake `CharsetDetector`).
4. `convert_controller_test.dart` — `Ok`→`AsyncData`, `Err`→`AsyncError` (override con fake use case), idle → `AsyncData(null)`.
5. `home_page_test.dart` — 4 estados (widget, override del controller).

## Migration / Rollout

No requiere migración ni feature flags (no hay estado persistido). Merge en un PR atómico.

## Rollback

`git revert <sha>` del PR (o `git reset --hard <sha-previo>`) revierte fuente y tests de una vez: el cambio es puramente en proceso, sin datos ni migraciones. La eliminación del estado mutable del registry no deja artefactos externos.

## Out of Scope

- **Fase 3**: extractores reales de los 7 sitios (hoy AO3/Fanfiction devuelven el HTML), descarga `.md` + BOM, `share_plus`/`path_provider`, charset con BOM y `<meta charset>`, y la suite completa de tests por capa.
- **Fase 4**: alineación con §3 (`app.dart`, `shared/providers/`, `routes/`, `core/{constants,theme,extensions}`, más use cases, `data/models/`, `data/platform/`, `home_page.dart`→`convert_page.dart`, y la divergencia `domain/extractors/` vs `data/extractors/`).

## Open Questions

- [ ] Cobertura transitoria: al derivar `detectSiteKey` de los extractores, solo AO3/Fanfiction quedan detectables; wiki/webnovel/royalroad/substack/blogger pasan a `unknown` hasta Fase 3. ¿Aceptable o se quiere un mapa fallback temporal? (Impacto bajo: `siteKey` no se muestra hoy.)
- [ ] Alineación futura del controller con el `Notifier<ConvertState>` sellado de §6.1 (ADR-2) — decidir si se unifica en Fase 4.
