// lib/features/convert/domain/extractors/extract_outcome.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';

/// Resultado inmutable de una extracción de contenido.
///
/// Reemplaza el estado mutable de lectura diferida del registro por un valor
/// explícito que viaja junto al HTML extraído.
class ExtractOutcome {
  /// HTML resultante de la extracción.
  final String html;

  /// Método de extracción aplicado.
  final ExtractionMethod method;

  /// Info del extractor usado (`siteName`) o `'generic'`; puede ser `null`.
  final String? info;

  const ExtractOutcome({required this.html, required this.method, this.info});
}
