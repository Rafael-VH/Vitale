// lib/features/convert/domain/extractors/extractor_registry.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';

abstract class ExtractorRegistry {
  SiteKey detectSiteKey(String? originUrl, String html);
  String extractContent(String html, {String? originUrl});
  ExtractionMethod getLastMethod();
  String? getLastFilterInfo();
}
