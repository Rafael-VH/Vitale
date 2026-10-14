// lib/features/convert/domain/extractors/extractor_registry.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/extractors/extract_outcome.dart';

/// Puerto de dominio para seleccionar el extractor adecuado y ejecutarlo.
abstract class ExtractorRegistry {
  /// Detecta la clave del sitio a partir de la [originUrl] y el [html].
  SiteKey detectSiteKey(String? originUrl, String html);

  /// Extrae el contenido del [html] y describe el resultado aplicado.
  ExtractOutcome extractContent(String html, {String? originUrl});
}
