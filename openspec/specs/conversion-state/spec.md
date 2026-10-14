# Delta for conversion-state

*Estado del flujo de conversión con Riverpod 3.x: controlador que traduce y página reactiva sin estado local.*

## ADDED Requirements

### Requirement: Controlador de estado de conversión

El sistema DEBE exponer un controlador Riverpod (`ConvertController`, `AsyncNotifier<ConversionResult?>`) con estados idle, loading, success y error para una solicitud de conversión.

#### Scenario: Estado inicial idle

- GIVEN la app recién iniciada
- WHEN no se solicitó ninguna conversión
- THEN el estado es idle (`AsyncData(null)`)

#### Scenario: Conversión exitosa

- GIVEN una entrada válida
- WHEN el controlador convierte
- THEN el estado es success con el `ConversionResult`

#### Scenario: Conversión fallida

- GIVEN una entrada que produce `Err(Failure)`
- WHEN el controlador convierte
- THEN el estado es error con un mensaje legible derivado de `failure.message`

### Requirement: El controlador solo traduce

`ConvertController` DEBE delegar en el caso de uso `ConvertHtmlToMarkdown`. NO DEBE contener lógica de negocio, validación ni acceso directo a repositorios.

#### Scenario: Delegación al use case

- GIVEN el controlador recibe una acción de conversión
- WHEN se ejecuta
- THEN invoca únicamente el use case y traduce su `Result` a estado, sin ramas de negocio

### Requirement: UI reactiva sin estado paralelo

`home_page.dart` DEBE consumir el estado con `ConsumerWidget` y `ref.watch`. NO DEBE mantener estado local paralelo vía `setState` para loading, resultado o error.

#### Scenario: La UI refleja el estado

- GIVEN el estado del controlador pasa a loading
- WHEN el widget reconstruye
- THEN muestra el indicador de carga sin `setState`

#### Scenario: Sin setState

- GIVEN `home_page.dart`
- WHEN se inspecciona
- THEN no hay llamadas a `setState` para loading, resultado o error

### Requirement: Estado aislado entre solicitudes

Una conversión nueva DEBE reemplazar el estado anterior sin filtrar método o info de la conversión previa.

#### Scenario: Segunda conversión limpia

- GIVEN una conversión previa exitosa (sitio A, método X)
- WHEN se convierte otro input (sitio B)
- THEN el estado refleja solo el segundo resultado, no método ni info del primero
