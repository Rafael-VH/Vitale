// lib/features/convert/domain/extractors/extractor_registry.dart
import '../entities/conversion_result.dart';

abstract class ExtractorRegistry {
  SiteKey detectSiteKey(String? originUrl, String html);
  String extractContent(String html, {String? originUrl});
  ExtractionMethod getLastMethod();
  String? getLastFilterInfo();
}
