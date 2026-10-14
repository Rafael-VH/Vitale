// lib/features/convert/domain/extractors/site_extractor.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';

/// Extractor de contenido específico de un sitio.
///
/// Expone su [siteKey] y sus [hostPatterns] para que el registro derive la
/// detección de sitio sin un mapa fijo de dominios.
abstract class SiteExtractor {
  /// Clave del sitio que este extractor representa.
  SiteKey get siteKey;

  /// Nombre legible del sitio (usado como info de la extracción).
  String get siteName;

  /// Patrones de host que este extractor reconoce (host exacto o subdominio).
  Set<String> get hostPatterns;

  /// Método de extracción aplicado por defecto.
  ExtractionMethod get extractionMethod => ExtractionMethod.siteSelector;

  /// Extrae el contenido relevante del [html] usando el [originUrl] opcional.
  String extract(String html, {String? originUrl});
}
