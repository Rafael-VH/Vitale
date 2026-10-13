// lib/features/convert/data/extractors/generic_extractor.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';

import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

class GenericExtractor implements SiteExtractor {
  @override
  String get siteName => 'generic';
  @override
  Set<String> get hostPatterns => const {};
  @override
  String extract(String html, {String? originUrl}) => html;

  @override
  ExtractionMethod get extractionMethod => throw UnimplementedError();
}
