import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/features/convert/data/extractors/ao3_extractor.dart';
import 'package:vitale/features/convert/data/extractors/fanfiction_extractor.dart';
import 'package:vitale/features/convert/data/extractors/generic_extractor.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

/// Extractor de prueba: hereda el default de `SiteExtractor` para
/// `extractionMethod` y solo declara lo abstracto.
class _FakeExtractor extends SiteExtractor {
  @override
  SiteKey get siteKey => SiteKey.ao3;

  @override
  String get siteName => 'ao3';

  @override
  Set<String> get hostPatterns => const {'archiveofourown.org'};

  @override
  String extract(String html, {String? originUrl}) => html;
}

void main() {
  group('SiteExtractor', () {
    test('los extractores reales exponen el siteKey esperado', () {
      expect(Ao3Extractor().siteKey, SiteKey.ao3);
      expect(FanfictionExtractor().siteKey, SiteKey.fanfiction);
      expect(GenericExtractor().siteKey, SiteKey.unknown);
    });

    test('extractionMethod por defecto es siteSelector sin lanzar', () {
      final SiteExtractor extractor = _FakeExtractor();

      expect(extractor.extractionMethod, ExtractionMethod.siteSelector);
    });
  });
}
