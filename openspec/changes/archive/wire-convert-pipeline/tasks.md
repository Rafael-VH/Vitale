# Tasks: Conectar el pipeline de conversión y el estado

Change: `wire-convert-pipeline` · Store: both · **Strict TDD activo** (`strict_tdd: true`) · Pace: interactive.

> Convención de tests: layout por capa `test/features/convert/{domain,data,presentation}/…` (testman/arquiman). Sin mockito/mocktail → fakes a mano, `ProviderContainer.test()` y `ProviderScope(overrides:)`.
> Regla: cada comportamiento tiene su test **antes** de la implementación (RED → GREEN). No hay task de implementación sin su task de test.

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~350–400 (fuente ≈ +130/−45, neto ≈ +85; + ~250 de tests) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-always |
| Chain strategy | pending |
| Review budget (session) | 1000 |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

Confirmación del design: la estimación ~350–400 con tests se confirma; cabe en un PR bajo el presupuesto de sesión (1000). Si los tests bordean los 400, se mantiene single PR amparado en el presupuesto de sesión (sin chaining). `Decision needed before apply: Yes` proviene de la estrategia `ask-always`, no de un exceso de tamaño.

### Suggested Work Units

| Unit | Goal (commit) |
|------|---------------|
| 1 | Contratos de dominio → `feat(convert): add ExtractOutcome and SiteKey extractor contract` |
| 2 | Detección derivada + landmines → `feat(convert): derive site detection from extractor host patterns` |
| 3 | originUrl → `feat(convert): extract originUrl from MHTML and pasted HTML` |
| 4 | Wiring repositorio → `refactor(convert): require injected detectors in repository` |
| 5 | Composition root → `feat(convert): wire conversion graph in providers` |
| 6 | `ConvertController` → `feat(convert): add ConvertController for conversion state` |
| 7 | `home_page` reactiva → `refactor(convert): make home page a ConsumerWidget` |

## Phase 1 — Contratos de dominio

- [x] 1.1 RED: `test/.../domain/extractors/extract_outcome_test.dart` — verifica `ExtractOutcome.html/method/info` (`info` opcional → `null`). Falla: el tipo no existe.
- [x] 1.2 GREEN: crear `lib/features/convert/domain/extractors/extract_outcome.dart` (VO inmutable; importa solo domain). `flutter test <archivo>` verde.
- [x] 1.3 RED: `test/.../domain/extractors/site_extractor_test.dart` — fake `SiteExtractor` declara `siteKey`; `extractionMethod` default = `siteSelector` sin lanzar.
- [x] 1.4 GREEN: `lib/.../domain/extractors/site_extractor.dart` — añadir `SiteKey get siteKey;`.
- [x] 1.5 RED/GREEN: `lib/.../domain/extractors/extractor_registry.dart` — `ExtractOutcome extractContent(String html, {String? originUrl})`; eliminar `getLastMethod`/`getLastFilterInfo`. RED = errores de compilación esperados en impl/callers (resueltos en Fase 2/4); `flutter analyze` confirma el cierre.

## Phase 2 — Data: registro de extractores

- [x] 2.1 RED: `test/.../data/extractors/extractor_registry_impl_test.dart` — `detectSiteKey` desde `hostPatterns` (host AO3 y subdominio → ao3; host sin match → `unknown`); `extractContent` devuelve `ExtractOutcome` con `method`/`info`; no-op → `generic`/`'generic'`; extractor que lanza → `GenericExtractor`; sin fuga entre dos conversiones.
- [x] 2.2 GREEN: `lib/.../data/extractors/extractor_registry_impl.dart` — derivar `detectSiteKey`, devolver `ExtractOutcome`, borrar `_lastMethod`/`_lastFilterInfo`.
- [x] 2.3 GREEN: `ao3_extractor.dart`, `fanfiction_extractor.dart`, `generic_extractor.dart` — `+SiteKey get siteKey`; borrar `extractionMethod => throw UnimplementedError()` (ao3/fanfiction heredan `siteSelector`; generic → `generic`). Test 2.1 verde; `rg "UnimplementedError" lib/features/convert/data/extractors/` → 0.

## Phase 3 — Data: originUrl

- [x] 3.1 RED: `test/.../data/datasources/site_detector_datasource_test.dart` — 4 señales (Snapshot-Content-Location → Content-Location http/https → canonical → og:url) + `null` sin señal.
- [x] 3.2 GREEN: `lib/.../data/datasources/site_detector_datasource.dart` — `String? extractOriginUrl(String raw)`. Verde.

## Phase 4 — Data: repositorio

- [x] 4.1 RED: `test/.../data/repositories/conversion_repository_impl_test.dart` — `originUrl` propagado a detección+extracción; deps requeridas (fake `CharsetDetector`, sin defaults ocultos); sitio desconocido → `Ok(ConversionResult)` con `siteKey == SiteKey.unknown`; entrada vacía → `Err(EmptyInputFailure)`.
- [x] 4.2 GREEN: `lib/.../data/repositories/conversion_repository_impl.dart` — requerir `mhtmlParser`/`siteDetector`/`charsetDetector`; usar `ExtractOutcome`; `originUrl` real; borrar `?? MhtmlParser()` / `?? CharsetDetectorImpl()` y los 4 call sites de `getLast*`. `flutter test` + `flutter analyze` limpios.

## Phase 5 — Composition root

- [x] 5.1 RED: `test/.../presentation/controllers/providers_test.dart` (`ProviderContainer.test()`) — `extractorRegistryProvider` registra Ao3+Fanfiction; `enginesProvider` tiene `Html2mdEngine` primero y los stubs con `isAvailable == false`; `convertHtmlToMarkdownProvider` resuelve.
- [x] 5.2 GREEN: `lib/.../presentation/controllers/providers.dart` — grafo completo (`mhtmlParserProvider`, `siteDetectorProvider`, `charsetDetectorProvider`, `enginesProvider`=[Html2md, MdreamJs, HtmlToMarkdownRs], `engineRegistryProvider`, `extractorRegistryProvider`=[Ao3, Fanfiction], `conversionRepositoryProvider` 5 deps, `convertHtmlToMarkdownProvider`). Verde.

## Phase 6 — conversion-state

- [x] 6.1 RED: `test/.../presentation/controllers/convert_controller_test.dart` — idle `AsyncData(null)`; `Ok`→`AsyncData(result)`; `Err`→`AsyncError(message)`; segunda conversión reemplaza estado (sin fuga). Override de `convertHtmlToMarkdownProvider` con fake.
- [x] 6.2 GREEN: `lib/.../presentation/controllers/convert_controller.dart` — `ConvertController extends AsyncNotifier<ConversionResult?>` + `convertControllerProvider`; solo traduce/delega. Verde.

## Phase 7 — home_page

- [x] 7.1 RED: `test/.../presentation/pages/home_page_test.dart` — 4 estados con `ProviderScope(overrides: [convertControllerProvider.overrideWith(...)])`; conservar `find.text('Vitale')` y `Pegar HTML` (`test/widget_test.dart` verde).
- [x] 7.2 GREEN: `lib/.../presentation/pages/home_page.dart` — `ConsumerWidget`, sin `setState`; `_PasteField extends StatefulWidget` para el `TextEditingController`; `ref.read(convertControllerProvider.notifier).convert(input)`; errores de pick por `SnackBar`. `flutter test` + `flutter analyze` limpios; `rg "setState" lib/features/convert/presentation/pages/home_page.dart` → 0.

## Phase 8 — Verificación de riesgos

- [x] 8.1 `rg -n "getLastMethod|getLastFilterInfo" lib/ test/` → 0 (sin callers residuales). PowerShell: `Select-String -Path lib/**/*.dart,test/**/*.dart -Pattern "getLastMethod|getLastFilterInfo"`.
- [x] 8.2 `rg -n "UnimplementedError" lib/features/convert/data/extractors/` → 0 (3 landmines eliminados).
- [x] 8.3 Degradación: assert `Ok(ConversionResult)` con `siteKey == SiteKey.unknown` para host sin extractor (de 4.1) — convierte, no falla.
- [x] 8.4 Cascada: assert `enginesProvider.first is Html2mdEngine` (de 5.1) y `flutter test test/markdown_engine_registry_impl_test.dart` verde.
- [x] 8.5 ArquiMan: `rg "package:flutter|from '.*data/|from '.*presentation/|from '\.\./" lib/features/convert/domain/` → 0; `flutter analyze` limpio.

## Revertibilidad

- Independientes: U1 (aditivo), U3 (archivo nuevo + test). U2 y U4 acoplados (4 depende de la firma `ExtractOutcome` de 2). U5–U7 forman la cadena de wiring. El cambio completo revierte atómico (`git revert`), sin datos ni migraciones.

## Deferred to later changes (excluidos de esta planificación)

- **Fase 3**: extractores reales de los 7 sitios; descarga `.md` + BOM; `share_plus`/`path_provider`; charset BOM y `<meta charset>`; suite de tests por capa completa.
- **Fase 4**: alineación con §3 (`app.dart`, `shared/providers/`, `routes/`, `core/{constants,theme,extensions}`, más use cases, `data/models/`, `data/platform/`, renombres y la divergencia `domain/extractors/` vs `data/extractors/`; `home_page`→`convert_page`). Alineación del controller con `Notifier<ConvertState>` (§6.1, ADR-2).
