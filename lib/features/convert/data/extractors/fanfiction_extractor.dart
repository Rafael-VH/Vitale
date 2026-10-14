// lib/features/convert/data/extractors/fanfiction_extractor.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';

import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

/// Extractor específico de FanFiction.Net.
///
/// Fase actual: fallback mínimo (devuelve el HTML sin filtrar); la extracción
/// real por selectores se implementa en una fase posterior.
class FanfictionExtractor extends SiteExtractor {
  @override
  SiteKey get siteKey => SiteKey.fanfiction;

  @override
  String get siteName => 'fanfiction';

  @override
  Set<String> get hostPatterns => const {'fanfiction.net'};

  @override
  String extract(String html, {String? originUrl}) => html;
}
