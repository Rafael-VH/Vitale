// lib/features/convert/data/extractors/ao3_extractor.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

/// Extractor específico de Archive of Our Own (AO3).
///
/// Fase actual: fallback mínimo (devuelve el HTML sin filtrar); la extracción
/// real por selectores se implementa en una fase posterior.
class Ao3Extractor extends SiteExtractor {
  @override
  SiteKey get siteKey => SiteKey.ao3;

  @override
  String get siteName => 'ao3';

  @override
  Set<String> get hostPatterns => const {
    'archiveofourown.org',
    'archiveofourown.com',
  };

  @override
  String extract(String html, {String? originUrl}) {
    // Fallback mínimo: devolver HTML sin filtrar (se mejora en iteraciones).
    return html;
  }
}
