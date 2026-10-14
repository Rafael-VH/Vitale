# Verify Report — `wire-convert-pipeline` (Re-verificación post-fix)

- **Cambio**: `wire-convert-pipeline`
- **Fecha**: 2026-10-13
- **Modo**: Strict TDD (`strict_tdd: true`)
- **Verificador**: sdd-verify (fase de verificación, auditoría adversarial)
- **Fuentes**: `specs/conversion-pipeline/spec.md`, `specs/conversion-state/spec.md`, `tasks.md`, `design.md`, `apply-progress` (Engram obs 867)
- **Naturaleza**: **re-verificación** tras un batch de apply de seguimiento que reclama cerrar W-1, W-2, W-3, S-1, S-3.
- **Estado**: `issues-found` — **Veredicto: `yes`** (la implementación coincide con los specs; 0 CRITICAL)

---

## 1. Resumen ejecutivo

Se reprodujeron los 6 comandos del DoD con salida literal: `flutter analyze` limpio, `flutter test` **53/53 verde** con conteo reconciliado (53 declaraciones `test(`/`testWidgets(` reales), y los 4 greps de no-regresión + `pubspec.yaml` sin cambios.

Los 5 hallazgos reclamados como cerrados (W-1, W-2, W-3, S-1, S-3) **quedan cerrados**: existen tests permanentes que pasan, y la **prueba de mutación** confirma que 6 de ellos fallan al revertir el fix/guarda correspondiente. La cobertura de escenarios sube a **24 PASS / 0 WARNING / 0 FAIL**, confirmando el score esperado.

Persisten dos observaciones no bloqueantes: (a) se aplicó un cambio no pedido por el hallazgo S-3 —orden-independencia de `_ogUrl` (el de `_canonical` SÍ estaba pedido)— que necesita una decisión registrada; (b) el test de W-1 es una guarda **parcial**: pasa aunque el motor preferido no disponible deje de excluirse del intento. No hay ningún hallazgo `CRITICAL`.

---

## 2. Evidencia literal — Definition of Done

| # | Comando | Salida | Resultado |
|---|---------|--------|-----------|
| 1 | `flutter analyze` | `No issues found! (ran in 3.0s)` | **PASS** |
| 2 | `flutter test` | `00:16 +53: All tests passed!` | **PASS** |
| 3 | `Select-String ... "getLastMethod\|getLastFilterInfo"` en `lib/`,`test/` | `0 matches` | **PASS** |
| 4 | `Select-String ... "UnimplementedError"` en `data/extractors/*` | `0 matches` | **PASS** |
| 5 | `Select-String ... "setState"` en `home_page.dart` | `0 matches` | **PASS** |
| 6 | `git diff --stat -- pubspec.yaml` | vacío | **PASS** |

### 2.1 Analyzer

```
$ flutter analyze
Analyzing Vitale...
No issues found! (ran in 3.0s)
```

### 2.2 Suite completa

```
$ flutter test
...
00:16 +53: All tests passed!
```

### 2.3 Greps de no-regresión

```
=== [3] getLastMethod|getLastFilterInfo in lib + test ===
0 matches
=== [4] UnimplementedError in data/extractors ===
0 matches
=== [5] setState in home_page.dart ===
0 matches
```

### 2.4 `pubspec.yaml` sin cambios

```
$ git diff --stat -- pubspec.yaml
(vacío)
```

---

## 3. Reconciliación de conteo (53 = 44 + 9)

Se contaron las declaraciones `test(` / `testWidgets(` en `test/`. El grep crudo arroja **57** coincidencias; **4 son falsos positivos** (`ProviderContainer.test(`, no son casos de test): 3 en `providers_test.dart` y 1 en `convert_controller_test.dart`. Total real = **57 − 4 = 53**, idéntico al número del runner.

| Archivo | Casos |
| --- | --- |
| `test/features/convert/data/datasources/site_detector_datasource_test.dart` | 12 |
| `test/features/convert/data/extractors/extractor_registry_impl_test.dart` | 10 |
| `test/features/convert/data/repositories/conversion_repository_impl_test.dart` | 6 |
| `test/features/convert/domain/extractors/extract_outcome_test.dart` | 2 |
| `test/features/convert/domain/extractors/site_extractor_test.dart` | 2 |
| `test/features/convert/presentation/controllers/convert_controller_test.dart` | 4 |
| `test/features/convert/presentation/controllers/providers_test.dart` | 3 |
| `test/features/convert/presentation/pages/home_page_test.dart` | 4 |
| `test/markdown_engine_registry_impl_test.dart` | 5 |
| `test/html2md_engine_test.dart` | 1 |
| `test/result_test.dart` | 3 |
| `test/widget_test.dart` | 1 |
| **Total** | **53** |

Delta del batch 2 = **+9**: `site_detector_datasource_test` +5, `markdown_engine_registry_impl_test` +3, `conversion_repository_impl_test` +1. **44 + 9 = 53** — el conteo reconcilia exactamente.

---

## 4. Auditoría adversarial del fix S-3 (mutation testing)

Archivo auditado: `lib/features/convert/data/datasources/site_detector_datasource.dart`.
Hash original del archivo (SHA-256): `CF935CCE734A4AB550C602BE969E2C3B92CDDACE5BB7E8978F8E13758FA7EDD0`. Se restauró byte-a-byte tras cada mutación (hash verificado igual) y `git status` quedó idéntico al inicial.

### 4.1 Confirmación del anclaje

`_contentLocation` está anclado con `^` y `multiLine: true` (líneas 17-21). Confirmado por lectura. Los `_canonical`/`_ogUrl` usan lookaheads sin orden fijo (líneas 25-35).

### 4.2 Mutación 1 — quitar `^` y `multiLine` de `_contentLocation`

Se revirtió el anclaje y se corrió el archivo de test. Salida literal (fragmento):

```
00:00 +7 -1: extractOriginUrl ignora Content-Location embebido en el cuerpo del documento [E]
  Expected: null
    Actual: 'http://decoy.example/inyectado</p>'
00:00 +7 -2: extractOriginUrl ignora X-Content-Location (el prefijo no es la cabecera real) [E]
  Expected: null
    Actual: 'http://decoy.example/x'
...
00:00 +10 -2: Some tests failed.
```

**2 tests fallan** (no 5). Reproduce el comportamiento de sub-tightening: sin ancla, el texto del cuerpo y el prefijo `X-` ganan. El happy path y canonical/og siguen verdes.

### 4.3 Mutación 2 — revertir `_canonical` a `rel`-antes-de-`href`

```
00:00 +10 -1: extractOriginUrl 5) usa canonical aunque href venga antes que rel [E]
  Expected: 'https://example.com/a'
    Actual: <null>
```

**1 test falla.** Confirma que el test 5 guarda la orden-independencia de `_canonical`.

### 4.4 Mutación 3 — revertir `_ogUrl` a `property`-antes-de-`content`

```
00:00 +11 -1: extractOriginUrl 6) usa og:url aunque content venga antes que property [E]
  Expected: 'https://example.com/og2'
    Actual: <null>
```

**1 test falla.** Confirma que el test 6 guarda la orden-independencia de `_ogUrl`.

### 4.5 Sondas de over/under-tightening (archivo desechable, luego eliminado)

Se creó `test/zz_tmp_probe_test.dart`, se ejecutó y se **eliminó** (árbol limpio, verificado). Resultado: `00:00 +9: All tests passed!`. Comportamiento observado:

| Sonda | Caso | Resultado |
| --- | --- | --- |
| P1 | Tab entre `:` y valor | captura correcta |
| P2 | Espacio inicial antes del nombre de cabecera | `null` (correcto: sería continuación) |
| P3 | Cabecera tras CRLF, no primera línea | captura correcta |
| P4 | Valor con CR colgante | captura correcta (trim) |
| P5 | Canonical con saltos de línea entre atributos | captura correcta |
| P6 | `>` dentro de URL entrecomillada (`href="...a>b"`) | devuelve `https://gt.example/a>b` (captura completa, no rompe) |
| P7 | og:url con comillas simples | captura correcta |
| P8 | Cabecera folded (continuación con espacios) | captura correcta |
| P9 | `rel` y `href` en etiquetas distintas | `null` (no cruza el cierre del tag) |

**Conclusión**: los regex mantienen el happy path (sin over-tightening en CRLF, tabs, saltos entre atributos, comillas simples), rechazan decoys de cuerpo/prefijo y no cruzan límites de etiqueta. No hay backtracking catastrófico (cuantificadores lineales `[^>]*`, sin anidamiento exponencial). Caso límite: con `>` **crudo** (no percent-encoded) dentro del valor y `rel`/`property` posteriores, el match falla — pero una URL con `>` sin escapar es inválida, se considera aceptable.

### 4.6 Juicio del cambio no pedido (`_canonical` / `_ogUrl` con lookaheads)

- **`_canonical`**: el hallazgo S-3 del reporte previo **sí nombraba** el caso `href`-primero ("`_canonical` exige `rel` antes de `href`; la forma `href`-primero no se detecta"). Por lo tanto **no es un cambio fuera de pedido**: es parte de S-3.
- **`_ogUrl`**: el hallazgo S-3 **NO** mencionaba `og:url`. La orden-independencia de `_ogUrl` es un cambio **no solicitado**, aunque es simétrico, de bajo riesgo, preserva el comportamiento previo (test 4 sigue verde) y está guardado por el test 6. Se registra como **N-1 (WARNING: necesita decisión registrada)**.

**Corrección de encuadre**: la afirmación de que "`_canonical` y `_ogUrl` se cambiaron sin que nadie lo pidiera" es parcialmente inexacta — `_canonical` estaba en S-3; solo `_ogUrl` es el extra.

### 4.7 ¿El cambio de lookahead introduce regresión de rendimiento o acepta atributos malformados?

No se halló regresión: las etiquetas con atributos en orden previo (`rel`→`href`, `property`→`content`) siguen detectándose (tests 3/4 y el happy path), y los lookaheads son de costo lineal sobre la etiqueta. No hay evidencia de aceptación de atributos malformados dentro de los casos probados.

---

## 5. Calidad de los tests nuevos — ¿guardan algo?

### 5.1 Mutación de W-2a (sin motores → `EngineUnavailableFailure`)

Se eliminó el branch `if (order.isEmpty) return Err(EngineUnavailableFailure());` en `markdown_engine_registry_impl.dart`:

```
00:00 +3 -1: sin motores disponibles → Err(EngineUnavailableFailure) [E]
  Expected: <Instance of 'EngineUnavailableFailure'>
    Actual: <Instance of 'AllEnginesFailedFailure'>
```

**Falla → guarda real.**

### 5.2 Mutación de W-2b (todos fallan → `AllEnginesFailedFailure`)

Se cambió el `return` terminal a `EngineUnavailableFailure`:

```
00:00 +4 -1: todos los motores fallan → Err(AllEnginesFailedFailure) [E]
  Expected: <Instance of 'AllEnginesFailedFailure'>
    Actual: <Instance of 'EngineUnavailableFailure'>
```

**Falla → guarda real.**

### 5.3 Mutación de W-3 (extracción vacía → `EmptyInputFailure` sin invocar el motor)

Se eliminó `if (filteredHtml.trim().isEmpty) return Err(EmptyInputFailure());` en `conversion_repository_impl.dart`:

```
00:00 +5 -1: extracción vacía → Err(EmptyInputFailure) sin invocar el motor [E]
  Expected: <Instance of 'Err<ConversionResult>>'
    Actual: <Instance of 'Ok<ConversionResult>'>
```

**Falla → guarda real.** El test además asserta la parte significativa `expect(engines.called, isFalse)` (línea 155), que confirma que el motor **no** se invoca. Verificado por lectura y por la mutación (sin la guarda, el repositorio llama al motor).

### 5.4 Mutación de W-1 (motor preferido no disponible → usa el siguiente disponible)

Se cambió `if (p == null || !p.isAvailable) return available;` por `if (p == null) return available;` (el preferido no disponible ya no se excluye):

```
00:00 +5: All tests passed!
```

**El test NO falla** → la guarda es **parcial**: el test verifica que "la conversión cae al siguiente motor disponible y devuelve `Ok`", pero no distingue entre *saltar* el motor no disponible y *intentarlo y descartarlo por `Err`*. El observable que sí diferenciaría es `EngineOutput.attempted`. Se registra como **N-2 (SUGGESTION)**. El escenario del spec (THEN: "se usa el siguiente motor disponible en el orden") **sí queda cubierto**; la debilidad es de granularidad, no de ausencia.

### 5.5 S-1 — eliminación de la tautología

`site_extractor_test.dart` ya no usa el fake tautológico; ahora asserta `siteKey` de los extractores **reales**:

```dart
expect(Ao3Extractor().siteKey, SiteKey.ao3);
expect(FanfictionExtractor().siteKey, SiteKey.fanfiction);
expect(GenericExtractor().siteKey, SiteKey.unknown);
```

La aserción puede fallar (un `siteKey` incorrecto o un `throw UnimplementedError()` reintroducido la rompería); la tautología desapareció. **Cerrado.**

---

## 6. Cobertura de escenarios (reconstruida)

### 6.1 `conversion-pipeline` (10 requisitos / 17 escenarios)

| Requisito | Escenario | Test | Resultado |
| --- | --- | --- | --- |
| R1 originUrl | URL de cabecera MHTML | repo "propaga el originUrl…" + detector "prioriza Snapshot-Content-Location" | PASS |
| R1 originUrl | URL de canonical en HTML pegado | detector "3) usa canonical" + "5) canonical href-first" | PASS |
| R1 originUrl | Origen no detectable | repo "origen no detectable → Ok … unknown" | PASS |
| R2 detección derivada | Coincidencia de host | registry "host exacto/subdominio AO3 + Fanfiction" | PASS |
| R2 detección derivada | Sin coincidencia | registry "host sin extractor → unknown" + "originUrl nulo → unknown" | PASS |
| R3 registro efectivo | Extractor registrado corre | providers "registra Ao3 y Fanfiction" + registry "extractor que transforma…" | PASS (S-2 diferido) |
| R4 resultado como valor | Resultado como valor | registry "extractor que transforma → method/info" | PASS |
| R4 resultado como valor | Sin fuga de estado | registry "sin fuga entre dos conversiones" | PASS |
| R5 fallback | Extractor no-op | registry "no-op del sitio (AO3) → generic" | PASS |
| R5 fallback | Extractor lanza | registry "extractor que lanza → cae al genérico" | PASS |
| R6 cascada | Motor preferido no disponible | markdown_engine "motor preferido no disponible → usa el siguiente disponible" | PASS |
| R6 cascada | Todos fallan / ninguno disponible | markdown_engine "sin motores → EngineUnavailableFailure" + "todos fallan → AllEnginesFailedFailure" | PASS |
| R7 registro de motores | El registro no rompe el default | providers "enginesProvider: Html2md primero…" | PASS |
| R8 entrada vacía | Entrada solo espacios | repo "entrada vacía → Err … sin invocar el motor" | PASS |
| R8 entrada vacía | Extracción vacía | repo "extracción vacía → Err … sin invocar el motor" | PASS |
| R9 charset inyectable | Detector inyectado | repo "usa el CharsetDetector inyectado" | PASS |
| R10 límites de alcance | Extracción real fuera de alcance | auditoría de alcance (§7) | PASS |

### 6.2 `conversion-state` (4 requisitos / 7 escenarios)

| Requisito | Escenario | Test | Resultado |
| --- | --- | --- | --- |
| R1 controlador | Estado inicial idle | convert_controller "idle → AsyncData(null)" | PASS |
| R1 controlador | Conversión exitosa | convert_controller "Ok → AsyncData(result)" | PASS |
| R1 controlador | Conversión fallida | convert_controller "Err → AsyncError(message)" | PASS |
| R2 solo traduce | Delegación al use case | convert_controller (3 casos) + lectura de código | PASS |
| R3 UI reactiva | La UI refleja el estado | home_page "loading: muestra el indicador de progreso" | PASS |
| R3 UI reactiva | Sin `setState` | grep §2.3 (0) | PASS |
| R4 aislamiento | Segunda conversión limpia | convert_controller "segunda conversión reemplaza el estado" | PASS |

**Totales**: 24 escenarios → **PASS 24 · WARNING 0 · FAIL 0 · UNVERIFIED 0**. Score esperado confirmado.

---

## 7. Regresión, scope drift y arquitectura

| Comprobación | Resultado | Evidencia |
| --- | --- | --- |
| Los 21 escenarios previos no regresaron | PASS | suite 53/53; los 7 tests previos de `site_detector_datasource_test` verdes |
| `pubspec.yaml` sin cambios | PASS | §2.4 |
| Sin `share_plus`/`path_provider`/BOM/`<meta charset>`/descarga `.md` en `lib/` | PASS | grep (única coincidencia `EngineId.mdreamJs` es falso positivo de `.md`) |
| Sin estructura fuera de alcance (`lib/app.dart`, `shared/`, `routes/`, `convert_page.dart`) | PASS | ausentes |
| Extractores siguen stub/no-op (sin selectores reales) | PASS | `ao3/fanfiction/generic` devuelven `html`; sin `querySelector`/`package:html` |
| Historial de archivo `lib/features/convert/data/repositories/conversion_repository_impl.dart` | — | (línea base del batch 1; sin cambios de alcance en batch 2) |
| Regla de dependencia: `domain/` no importa `data/`,`presentation/`, Flutter | PASS | imports solo `core/errors` + `domain/` |
| Sin imports relativos en `lib/` | PASS | grep `0 matches` |
| `tasks.md` no falsificado | PASS | 23/23 `[x]`, 0 `[ ]`; el batch 2 no marcó ningún task nuevo (los hallazgos de verify no tenían task abierta) |
| S-2 dejado diferido | PASS | no hay test que invoque `Ao3Extractor.extract` vía el registro cableado por provider (hoy no-op, inobservable); consistente con apply-progress |

---

## 8. Hallazgos

### WARNING

- **N-1 — Cambio no solicitado en `_ogUrl` (orden-independencia con lookahead).**
  `lib/features/convert/data/datasources/site_detector_datasource.dart:32-35`. El hallazgo S-3 no mencionaba `og:url`; sin embargo el batch lo hizo orden-independiente. Es simétrico, de bajo riesgo, preserva el comportamiento previo y está guardado por el test 6 (falla al revertir, §4.4). A diferencia de esto, `_canonical` **sí** estaba nombrado en S-3 y por eso no se cuenta aquí. **Acción**: registrar la decisión (aceptar como hardening simétrico o revertir `_ogUrl` al orden fijo). No bloquea.

### SUGGESTION

- **N-2 — Guarda parcial en el test de W-1.**
  `test/markdown_engine_registry_impl_test.dart:41-48`. El test pasa aunque el motor preferido no disponible deje de excluirse del intento (§5.4). **Acción**: assertar `EngineOutput.attempted` para verificar que el motor no disponible se *salta* (no se intenta). El escenario del spec ya está cubierto; esto solo endurece la guarda.

- **N-3 — Precisión de la expectativa de mutación de S-3.**
  Ninguna reversión única hace fallar los 5 tests de S-3: 2 fallan al des-anclar `_contentLocation`, 1 al revertir `_canonical`, 1 al revertir `_ogUrl`; el 5º ("usa Content-Location real al inicio de línea") solo guarda contra over-tightening. Esto es consistente con el RED declarado por apply ("4 fallos observados"), no un defecto. **Acción**: ninguna; nota de precisión para futuras re-verificaciones.

### CRITICAL

Ninguno.

---

## 9. Claims verificados / refutados

**Verificados** (contra código y ejecución real):
- `flutter analyze` limpio → confirmado (§2.1).
- `flutter test` 53/53, `44 → 53` → confirmado (§2.2, §3). El delta +9 coincide por archivo.
- `_contentLocation` anclado (`^` + `multiLine`) → confirmado (§4.1) y con mutación (§4.2).
- `_canonical`/`_ogUrl` orden-independientes → confirmado y guardado (§4.3, §4.4).
- W-1/W-2/W-3/S-1/S-3 cerrados → confirmado (§4, §5).
- Sin dependencias nuevas / sin scope drift → confirmado (§7).

**Refutados / matizados**: ninguno de fondo. Dos matices de encuadre:
1. El cambio "no pedido" abarca solo `_ogUrl`; `_canonical` estaba dentro de S-3 (§4.6).
2. La expectativa "los 5 tests de S-3 fallan al revertir" no es exacta; el RED aplicable es de 4 fallos (§5.5/N-3), lo que coincide con lo declarado por apply-progress.

**No verificable**: que el ciclo RED se haya observado cronológicamente en cada task (no hay historial en el árbol); GREEN sí está verificado, y la mutación confirma que los guards son reales.

---

## 10. Veredicto y siguiente paso

- **Veredicto**: `yes` — la implementación coincide con los specs. Los 5 hallazgos del reporte previo quedan cerrados; **24/24 escenarios** con test permanente en verde; 0 CRITICAL; DoD 6/6 PASS; sin regresiones ni scope drift funcional.
- **Observaciones no bloqueantes**: N-1 (decisión sobre `_ogUrl`, WARNING), N-2 (guarda parcial de W-1, SUGGESTION), N-3 (precisión, SUGGESTION).
- **Siguiente fase**: `archive`. No hay blocker. Si se desea, registrar N-1 en `design.md` como decisión; N-2 queda como deuda de test opcional.
