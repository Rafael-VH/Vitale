# Archive Report — wire-convert-pipeline

**Change**: `wire-convert-pipeline`  
**Project**: `vitale`  
**Final status**: Change completed and archived; implementation matches spec.  
**Verdict (verify)**: `yes` (0 CRITICAL, 24/24 scenarios PASS, 53/53 tests green)  
**Date**: 2026-10-13  
**Artifact store**: `both` (files under `openspec/` + Engram with `topic_key: sdd/wire-convert-pipeline/archive-report`, `project: vitale`, `capture_prompt: false`)

---

## What shipped

The wired conversion pipeline (runtime wiring connecting MHTML/HTML → site detection → extraction → Markdown, and Riverpod 3.x state):

- **originUrl extraction**: `SiteDetectorDataSource.extractOriginUrl()` extracts `originUrl` from MHTML in order: `Snapshot-Content-Location`, `Content-Location` (http/https), `<link rel="canonical">`, `og:url`. For pasted HTML, canonical/og:url are applied when present. Propagated to site detection and content extraction (R1). Behavior with no signals returns `originUrl = null` and `siteKey = SiteKey.unknown` without failing.
- **Site detection derived from extractors**: `detectSiteKey()` derives from registered extractors' `hostPatterns` (no fixed map). `SiteExtractor` now exposes `siteKey`. Host matches return that `SiteKey`; otherwise `SiteKey.unknown` (R2). Transitional coverage: only AO3/Fanfiction detectable via `hostPatterns` until real per-site extractors exist (Phase 3); other hosts degrade to `unknown` and still convert via generic fallback (recorded and accepted).
- **Effective extractor registration**: `ExtractorRegistryImpl` registers `Ao3Extractor` and `FanfictionExtractor`. `extractContent()` now returns an immutable `ExtractOutcome` `{html, method, info}` (replaced `getLastMethod`/`getLastFilterInfo`, eliminating mutable state leakage between conversions). Fallback behavior: if a registered extractor returns input unchanged (no-op) or throws, system falls back to `GenericExtractor` (method `generic`, info `generic`); extractors no longer throw `UnimplementedError()` (R3-R5).
- **Effective engine registration and cascade**: `MarkdownEngineRegistryImpl` attempts preferred engine first (`html2md` by default). If unavailable, returns empty output, or fails, it tries the next available engine in order. Unavailable engines (`MdreamJsEngine`, `HtmlToMarkdownRsEngine`) registered with `isAvailable = false` and skipped without breaking conversion. On all engines fail → `Err(AllEnginesFailedFailure)`. If no engines available → `Err(EngineUnavailableFailure)` (R6-R7).
- **Empty input handling**: `Err(EmptyInputFailure)` for empty/whitespace input or extraction producing empty string; extractors/engines not invoked in those cases (R8).
- **Injected CharsetDetector**: `ConversionRepositoryImpl` receives `CharsetDetector` via constructor from composition root (no hidden default instantiation) (R9). Wiring also injects `MhtmlParser` and `SiteDetectorDataSource` via required params.
- **Conversion state (Riverpod 3.x)**: `ConvertController` extends `AsyncNotifier<ConversionResult?>` with `convertControllerProvider`. States map to `AsyncValue` (idle = `AsyncData(null)`, success = `AsyncData(result)`, failure = `AsyncError(failure.message)`). Controller delegates only to `ConvertHtmlToMarkdown` (no business logic). `HomePage` converted to `ConsumerWidget`, removed all `setState` usage for loading/result/error; pasted input uses a small `StatefulWidget` only for `TextEditingController` lifecycle. (conversion-state R1-R4)

**Evidence**
- `flutter analyze`: clean (`No issues found! (ran in 3.0s)`)
- `flutter test`: 53/53 green (`00:16 +53: All tests passed!`) — 7 pre-existing + 46 added (9 in follow-up batch). Test count reconciled (53 real test/testWidgets declarations).
- 24/24 scenarios PASS; mutation testing confirms guards are effective (W-1/W-2/W-3/S-1/S-3 closed). No new dependencies added.
- Dependency rule intact (domain has no outward imports to data/presentation/Flutter; no relative imports).

---

## ADRs recorded (from design)

- **ADR-1 — ExtractOutcome returned as value (no mutable state)**: `ExtractorRegistry.extractContent()` returns immutable `ExtractOutcome` in domain instead of exposing `getLastMethod`/`getLastFilterInfo` (mutable, leakage risk). `ExtractOutcome` lives in domain (return type of domain port). Accepted.
- **ADR-2 — AsyncNotifier<ConversionResult?> (not sealed ConvertState)**: Uses Riverpod `AsyncNotifier<ConversionResult?>` with `AsyncData(null)` for idle; covers 4 states with minimal boilerplate. Diverges from spec §6.1 text proposing `Notifier<ConvertState>` (recorded below as deferred alignment). Accepted for this phase.
- **ADR-3 — Register engines even if unavailable**: Register all 3 engines in providers; stubs report `isAvailable = false` and are skipped by cascade. Keeps providers free of Flutter platform branching and preserves documented cascade. Accepted.
- **ADR-4 — Separate SiteDetectorDataSource**: New `data/datasources/site_detector_datasource.dart` (`extractOriginUrl(String raw)`) instead of adding heuristics to `MhtmlParser`. Single responsibility, works for MHTML and pasted HTML. Accepted.
- **ADR-5 — No hidden instantiation in data**: `ConversionRepositoryImpl` requires injected `mhtmlParser`, `siteDetector`, `charsetDetector` (no `??` defaults). Wiring lives only in composition root. Accepted.

---

## Decisions to record explicitly

### N-1 (WARNING) — `_ogUrl` order-independence (un-requested, but accepted)
The follow-up batch made `_canonical` and `_ogUrl` attribute-order independent via lookaheads (not limited to `rel` before `href` or `property` before `content`).
- `_canonical`: the S-3 finding explicitly named the `href`-first case as missing; making it order-independent was part of closing S-3 (requested).
- `_ogUrl`: the S-3 finding did **not** mention `og:url`. The order-independence change for `_ogUrl` was **un-requested churn**. It preserves prior behavior, is symmetric with `_canonical`, is low-risk, and is guarded by a new test that fails if reverted (mutation test confirms the guard).  
**Decision recorded**: Accepted as symmetric hardening (non-blocking). No functional regression introduced.

### N-2 (SUGGESTION) — W-1 preferred-engine guard is partial
The test for W-1 verifies the cascade falls back to the next available engine and returns `Ok`, but does not distinguish “skip unavailable preferred engine (do not attempt it)” from “attempt it and discard on Err”. The observable `EngineOutput.attempted` would make this distinction.  
**Decision recorded**: The scenario from spec is satisfied (behavior correct). The guard’s granularity is partial; this is a test-hardening suggestion, not a blocker. Deferred as optional test improvement (no code change required for correctness).

### S-2 (deferred) — Proving “a registered extractor actually runs”
To prove “a registered extractor actually runs” when its host matches, the test would need to observe invocation of a real extractor instance via the wired registry/providers (not just detectSiteKey). With current stubs (AO3/Fanfiction return input unchanged), invocation is not meaningfully observable.  
**Decision recorded**: Deferred to Phase 3 when real per-site extractors exist (their behavior makes invocation observable and worth asserting). Not blocking for this wiring change.

### ADR-2 divergence — Controller contract alignment
The implementation uses `ConvertController extends AsyncNotifier<ConversionResult?>` (and `AsyncValue` states) while spec §6.1 text proposes `Notifier<ConvertState>` (sealed 4-state). This is an intentional divergence per ADR-2 (minimal boilerplate).  
**Decision recorded**: Alignment deferred to Phase 4 (structural alignment work). The functional behavior of idle/loading/success/error is preserved and covered by tests.

### Transitional detection coverage
Only AO3 and Fanfiction are detectable via `hostPatterns` until real per-site extractors exist (Phase 3). Other hosts degrade to `SiteKey.unknown` and still convert via the generic fallback.  
**Decision recorded**: Accepted as transitional state. No behavior regression relative to previous wiring; fallback path remains functional. To be expanded in Phase 3.

---

## Deferred / next changes

### Phase 3
- Real per-site extractors for the 7 sites
- `.md` download + UTF-8 BOM
- `share_plus`/`path_provider` wiring
- Charset handling improvements (BOM + `<meta charset>`)
- Full per-layer test suite expansion

### Phase 4
- §3 structural alignment: `lib/app.dart`, `lib/shared/providers/`, `lib/routes/`, `core/{constants,theme,extensions}`, `core/utils/{utf8_bom,filename_sanitizer,quoted_printable_decoder}.dart`
- Domain/entities alignment: `domain/entities/{mhtml_document,site_key,extractor_config}.dart`
- Remaining use cases and repository ports; `data/models/`, `data/platform/`
- Renames: `home_page.dart` → `convert_page.dart`
- Controller alignment per ADR-2 divergence (`AsyncNotifier<ConversionResult?>` → `Notifier<ConvertState>` as specified in §6.1, if chosen)

### S-2 (deferred)
- The deferred extractor-invocation guard (prove registered extractor actually runs via wired registry) — tied to Phase 3 real extractors.

---

## Rollback
Purely in-process: `git revert` of the PR. No data or migrations involved.

---

## Skills used
- `cognitive-doc-design` (scannable, review-facing archive report)
- `work-unit-commits` (work-unit sanity check against shipped changes)

---

## Artifacts
- **Canonical specs (synced)**:
  - `openspec/specs/conversion-pipeline/spec.md` — 10 requirements / 17 scenarios (14 requirements / 24 total across both capabilities)
  - `openspec/specs/conversion-state/spec.md` — 4 requirements / 7 scenarios
- **Archived change**: `openspec/changes/archive/wire-convert-pipeline/` containing `proposal.md`, `design.md`, `tasks.md`, `verify-report.md`, and `specs/conversion-pipeline/spec.md`, `specs/conversion-state/spec.md` (historical record; preserved)
- **Archive report**: `openspec/changes/archive/wire-convert-pipeline/archive-report.md`
- **Engram** (stored per instructions): `topic_key: "sdd/wire-convert-pipeline/archive-report"`, `project: "vitale"`, `capture_prompt: false`

**Specs synced counts**: 14 requirements / 24 scenarios (carried over intact; no weakening/drops).  
**Change location**: `openspec/changes/archive/wire-convert-pipeline/`

---

## Risks
None identified. The only non-blocking items are N-1 (recorded decision), N-2 (optional test hardening), N-3 (note precision), S-2 (deferred to Phase 3), and ADR-2 divergence (deferred to Phase 4). No loss of requirements/scenarios; canonical specs are faithful copies.

---

## Next recommended
Maintainer to handle git explicitly (do not commit/push/PR from this phase): create/commit the archived state as appropriate per repo workflow. No further action required from archive phase.
