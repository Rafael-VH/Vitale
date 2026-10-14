# Delta for conversion-pipeline

*Conexión runtime del pipeline MHTML/HTML → sitio → extracción → Markdown. Solo comportamiento de wiring; la lógica real por sitio queda fuera de alcance.*

## ADDED Requirements

### Requirement: Extracción del originUrl

El sistema DEBE extraer el `originUrl` del MHTML probando, en orden: `Snapshot-Content-Location`, `Content-Location` (http/https), `<link rel="canonical">` y `og:url`. Con HTML pegado DEBE aplicar la misma detección sobre el propio HTML cuando haya señales disponibles. El `originUrl` DEBE propagarse a la detección de sitio y a la extracción de contenido.

#### Scenario: URL recuperada de cabecera MHTML

- GIVEN un MHTML con `Snapshot-Content-Location`
- WHEN el repositorio convierte el input
- THEN `originUrl` es esa URL
- AND esa URL se usa para detectar el sitio y extraer contenido

#### Scenario: URL recuperada de canonical en HTML pegado

- GIVEN HTML pegado con `<link rel="canonical" href="...">`
- WHEN se convierte
- THEN `originUrl` proviene del canonical

#### Scenario: Origen no detectable

- GIVEN entrada sin ninguna de las cuatro señales de URL
- WHEN se convierte
- THEN `originUrl` es `null` y `siteKey` es `SiteKey.unknown`
- AND la conversión devuelve `Ok(ConversionResult)` (no falla)

### Requirement: Detección de sitio derivada de extractores

`detectSiteKey` DEBE derivarse de los `hostPatterns` de los extractores registrados, no de un mapa fijo. `SiteExtractor` DEBE exponer su `SiteKey` junto a sus `hostPatterns`.

#### Scenario: Coincidencia de host

- GIVEN un extractor registrado con `hostPatterns` y `SiteKey`
- WHEN la URL coincide con el host (igual o subdominio)
- THEN `detectSiteKey` devuelve ese `SiteKey`

#### Scenario: Sin coincidencia

- GIVEN una URL cuyo host no coincide con ningún extractor
- WHEN se detecta el sitio
- THEN devuelve `SiteKey.unknown`

### Requirement: Registro efectivo de extractores

El composition root DEBE registrar los extractores (`Ao3Extractor`, `FanfictionExtractor`) en el `ExtractorRegistry`, de modo que un extractor registrado se ejecute cuando su host coincide.

#### Scenario: Extractor registrado corre

- GIVEN un `originUrl` con host AO3
- WHEN se extrae contenido
- THEN se invoca `Ao3Extractor.extract`

### Requirement: Extracción devuelve su resultado

`ExtractorRegistry.extractContent` DEBE devolver un `ExtractOutcome` inmutable con el HTML, el `ExtractionMethod` y la info del extractor usado. El registro NO DEBE exponer estado mutable de lectura diferida (`getLastMethod`/`getLastFilterInfo`).

#### Scenario: Resultado como valor

- GIVEN un extractor que transforma el HTML
- WHEN se llama `extractContent`
- THEN el retorno incluye `method` e `info` del extractor usado

#### Scenario: Sin fuga de estado entre conversiones

- GIVEN dos conversiones consecutivas de sitios distintos
- WHEN corre la segunda
- THEN su `ExtractOutcome` refleja solo su propio input

### Requirement: Fallback de extracción

Si un extractor registrado devuelve el HTML de entrada sin cambios o lanza, el sistema DEBE caer al `GenericExtractor` y la conversión DEBE continuar. `SiteExtractor.extractionMethod` DEBE exponer un valor válido y NO DEBE lanzar `UnimplementedError`.

#### Scenario: Extractor no-op

- GIVEN un extractor cuyo `extract` devuelve el HTML idéntico
- WHEN se extrae
- THEN `method == ExtractionMethod.generic` e `info == 'generic'`

#### Scenario: Extractor lanza

- GIVEN un extractor cuyo `extract` lanza una excepción
- WHEN se extrae
- THEN se usa el `GenericExtractor` y la conversión no falla por esa excepción

### Requirement: Cascada de motores

El registro de motores DEBE intentar el motor preferido (por defecto `html2md` primero) y, ante `Err`, salida vacía o motor no disponible, probar el siguiente disponible. Un motor no disponible DEBE reportarse como no disponible y saltarse sin romper la conversión.

#### Scenario: Motor preferido no disponible

- GIVEN el motor preferido con `isAvailable == false`
- WHEN se convierte
- THEN se usa el siguiente motor disponible en el orden

#### Scenario: Todos los motores fallan

- GIVEN todos los motores disponibles devuelven `Err`
- WHEN se convierte
- THEN `Err(AllEnginesFailedFailure)`, no un crash
- AND si no hay ningún motor disponible → `Err(EngineUnavailableFailure)`

### Requirement: Registro efectivo de motores

El composition root DEBE registrar los motores en `MarkdownEngineRegistryImpl` para que la cascada documentada ocurra. Los stubs no disponibles (`MdreamJsEngine`, `HtmlToMarkdownRsEngine`) DEBEN registrarse con `isAvailable == false` sin alterar la conversión por defecto.

#### Scenario: El registro no rompe el default

- GIVEN la app en cualquier plataforma
- WHEN se arma el registro de motores
- THEN `html2md` permanece primero y los stubs no rompen la conversión

### Requirement: Entrada vacía

El sistema DEBE devolver `Err(EmptyInputFailure)` para entrada vacía o solo espacios en blanco, sin invocar extractores ni motores.

#### Scenario: Entrada solo espacios

- GIVEN un `PastedInput('   ')`
- WHEN se convierte
- THEN `Err(EmptyInputFailure)`

#### Scenario: Extracción vacía

- GIVEN contenido cuya extracción produce cadena vacía
- WHEN se convierte
- THEN `Err(EmptyInputFailure)`

### Requirement: Inyección de CharsetDetector

`ConversionRepositoryImpl` DEBE recibir su `CharsetDetector` por constructor desde el composition root; la capa data NO DEBE instanciar un default (`CharsetDetectorImpl`) internamente.

#### Scenario: Detector inyectado

- GIVEN el repositorio armado por provider con un `CharsetDetector` inyectado
- WHEN decodifica bytes de un `FileInput`
- THEN usa el detector inyectado (override-able en tests)

### Requirement: Límites de alcance

Este cambio NO DEBE incluir lógica real de extracción por sitio, descarga `.md`/BOM, compartir, ni charset BOM/`<meta charset>`. Los extractores de sitio PUEDEN seguir devolviendo el HTML como placeholder.

#### Scenario: Extracción real fuera de alcance

- GIVEN un sitio soportado
- WHEN se define este cambio
- THEN la lógica real de selectores queda fuera; solo se garantiza el wiring
