# Proposal: Conectar el pipeline de conversión y el estado

## Intent
La arquitectura de `lib/` está completa pero desconectada: `flutter analyze` pasa y los tests 7/7, pero la conversión nunca corre completa. `extractorRegistryProvider` registra una lista vacía, `originUrl` viaja en `null`, los motores stub no se registran, y `home_page.dart` usa `setState` local. Este cambio conecta el wiring real y mueve el estado a Riverpod 3.x (§3, §4, §6.5).

## Scope
### In Scope
- Nuevo `SiteDetectorDataSource` que extrae `originUrl` del MHTML (§5.2) e inyectarlo en `ConversionRepositoryImpl` (hoy `null` en `convert()`).
- Registrar `Ao3Extractor`/`FanfictionExtractor` y los motores `MdreamJsEngine`/`HtmlToMarkdownRsEngine` en `providers.dart`.
- Derivar `detectSiteKey` de los `hostPatterns`; exponer `SiteKey` en `SiteExtractor`.
- Quitar `extractionMethod => throw UnimplementedError()`.
- Inyectar `CharsetDetector` por provider; eliminar defaults `?? CharsetDetectorImpl()`.
- Reemplazar `getLastMethod()/getLastFilterInfo()` por un retorno `ExtractOutcome`.
- `ConvertController` (`AsyncNotifier<ConversionResult?>`) + provider; `home_page.dart` → `ConsumerWidget` sin `setState`.

### Out of Scope
- Fase 3: extractores reales de los 7 sitios; descarga `.md` + BOM; `share_plus`/`path_provider`; charset con BOM; tests.
- Fase 4: alineación con §3 (`app.dart`, `shared/providers/`, `routes/`, `core/{constants,theme,extensions}`, más use cases, `data/models/`, `data/platform/`, renombres y la divergencia `domain/extractors/` vs `data/extractors/`).

## Capabilities
### New Capabilities
- `conversion-pipeline`: ejecución runtime MHTML/HTML → sitio → extracción → Markdown (originUrl real, registro de extractores/motores, `ExtractOutcome`).
- `conversion-state`: estado del flujo con Riverpod 3.x (`ConvertController` + página sin `setState`).

### Modified Capabilities
- None (sin specs previos en `openspec/specs/`).

## Approach
Completar el composition root; extraer `originUrl` en data; cambiar `ExtractorRegistry` a un retorno `ExtractOutcome`; añadir un `AsyncNotifier` que traduce UI ↔ `ConvertHtmlToMarkdown`.

## Affected Areas
| Area | Impact |
|------|--------|
| `data/datasources/site_detector_datasource.dart` | New |
| `presentation/controllers/providers.dart` | Modified |
| `data/repositories/conversion_repository_impl.dart` | Modified |
| `data/extractors/*.dart` | Modified |
| `domain/extractors/*.dart`, `domain/entities/*.dart` | Modified/New |
| `presentation/controllers/convert_controller.dart` | New |
| `presentation/pages/home_page.dart` | Modified |

## Risks
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Nuevo contrato `ExtractorRegistry` rompe callers | Med | Revisar callers; tests del registry |
| `SiteDetectorDataSource` no halla URL | Med | 4 heurísticas; fallback `SiteKey.unknown` |
| Cascada altera output | Low | Stubs devuelven `Err`; `html2md` primero |

## Rollback Plan
`git revert` atómico del PR; sin migraciones ni datos persistentes.

## Dependencies
Ninguna nueva (solo paquetes ya presentes).

## Success Criteria
- [ ] Extractores y motores registrados; `originUrl` real al pipeline.
- [ ] `flutter analyze` limpio y `flutter test` verde (7/7).
- [ ] `home_page.dart` sin `setState`.
- [ ] MHTML con `<link rel=canonical>` da `siteKey` ≠ `unknown`.

## Session Constraints
Pace `interactive` · store `both` · PR `ask-always` · budget 1000 líneas. ~12 archivos / 300–450 líneas → un PR.
