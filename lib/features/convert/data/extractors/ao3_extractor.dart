// lib/features/convert/data/extractors/ao3_extractor.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

class Ao3Extractor implements SiteExtractor {
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

  @override
  ExtractionMethod get extractionMethod => throw UnimplementedError();
}
