// lib/features/convert/data/extractors/generic_extractor.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';

import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

/// Extractor genérico de respaldo (sin filtrado específico de sitio).
class GenericExtractor extends SiteExtractor {
  @override
  SiteKey get siteKey => SiteKey.unknown;

  @override
  String get siteName => 'generic';

  @override
  Set<String> get hostPatterns => const {};

  @override
  ExtractionMethod get extractionMethod => ExtractionMethod.generic;

  @override
  String extract(String html, {String? originUrl}) => html;
}
