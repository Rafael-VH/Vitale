// lib/features/convert/data/extractors/fanfiction_extractor.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';

import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

class FanfictionExtractor implements SiteExtractor {
  @override
  String get siteName => 'fanfiction';
  @override
  Set<String> get hostPatterns => const {'fanfiction.net'};
  @override
  String extract(String html, {String? originUrl}) => html;

  @override
  ExtractionMethod get extractionMethod => throw UnimplementedError();
}
