// lib/features/convert/data/extractors/generic_extractor.dart
import '../../domain/extractors/site_extractor.dart';

class GenericExtractor implements SiteExtractor {
  @override
  String get siteName => 'generic';
  @override
  Set<String> get hostPatterns => const {};
  @override
  String extract(String html, {String? originUrl}) => html;
}
