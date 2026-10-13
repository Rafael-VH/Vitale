// lib/features/convert/domain/extractors/site_extractor.dart
import '../../domain/entities/conversion_result.dart';

abstract class SiteExtractor {
  String get siteName;
  Set<String> get hostPatterns;
  ExtractionMethod get extractionMethod => ExtractionMethod.siteSelector;
  String extract(String html, {String? originUrl});
}
