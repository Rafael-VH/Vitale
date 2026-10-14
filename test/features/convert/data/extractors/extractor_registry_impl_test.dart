import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/features/convert/data/extractors/ao3_extractor.dart';
import 'package:vitale/features/convert/data/extractors/extractor_registry_impl.dart';
import 'package:vitale/features/convert/data/extractors/fanfiction_extractor.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

/// Extractor de prueba que transforma el HTML (no es no-op).
class _TransformingExtractor extends SiteExtractor {
  @override
  SiteKey get siteKey => SiteKey.webnovel;

  @override
  String get siteName => 'fake';

  @override
  Set<String> get hostPatterns => const {'example.com'};

  @override
  String extract(String html, {String? originUrl}) => '<article>$html</article>';
}

/// Extractor de prueba que lanza durante la extracción.
class _ThrowingExtractor extends SiteExtractor {
  @override
  SiteKey get siteKey => SiteKey.royalroad;

  @override
  String get siteName => 'boom';

  @override
  Set<String> get hostPatterns => const {'boom.com'};

  @override
  String extract(String html, {String? originUrl}) =>
      throw StateError('boom');
}

void main() {
  group('detectSiteKey derivado de hostPatterns', () {
    final registry = ExtractorRegistryImpl([Ao3Extractor(), FanfictionExtractor()]);

    test('host exacto de AO3 → ao3', () {
      expect(
        registry.detectSiteKey('https://archiveofourown.org/works/1', '<p>x</p>'),
        SiteKey.ao3,
      );
    });

    test('subdominio de AO3 → ao3', () {
      expect(
        registry.detectSiteKey('https://www.archiveofourown.org/works/1', '<p>x</p>'),
        SiteKey.ao3,
      );
    });

    test('host de Fanfiction → fanfiction', () {
      expect(
        registry.detectSiteKey('https://www.fanfiction.net/s/1', '<p>x</p>'),
        SiteKey.fanfiction,
      );
    });

    test('host sin extractor → unknown', () {
      expect(
        registry.detectSiteKey('https://example.org/nada', '<p>x</p>'),
        SiteKey.unknown,
      );
    });

    test('originUrl nulo → unknown', () {
      expect(registry.detectSiteKey(null, '<p>x</p>'), SiteKey.unknown);
    });
  });

  group('extractContent devuelve ExtractOutcome', () {
    test('no-op del sitio (AO3) → generic y "generic"', () {
      final registry = ExtractorRegistryImpl([Ao3Extractor()]);

      final outcome = registry.extractContent(
        '<p>x</p>',
        originUrl: 'https://archiveofourown.org/works/1',
      );

      expect(outcome.method, ExtractionMethod.generic);
      expect(outcome.info, 'generic');
      expect(outcome.html, '<p>x</p>');
    });

    test('extractor que transforma → method/info del extractor', () {
      final registry = ExtractorRegistryImpl([_TransformingExtractor()]);

      final outcome = registry.extractContent(
        '<p>x</p>',
        originUrl: 'https://example.com/a',
      );

      expect(outcome.method, ExtractionMethod.siteSelector);
      expect(outcome.info, 'fake');
      expect(outcome.html, '<article><p>x</p></article>');
    });

    test('extractor que lanza → cae al genérico', () {
      final registry = ExtractorRegistryImpl([_ThrowingExtractor()]);

      final outcome = registry.extractContent(
        '<p>x</p>',
        originUrl: 'https://boom.com/a',
      );

      expect(outcome.method, ExtractionMethod.generic);
      expect(outcome.info, 'generic');
      expect(outcome.html, '<p>x</p>');
    });

    test('host desconocido → genérico', () {
      final registry = ExtractorRegistryImpl([Ao3Extractor()]);

      final outcome = registry.extractContent(
        '<p>x</p>',
        originUrl: 'https://example.org/nada',
      );

      expect(outcome.method, ExtractionMethod.generic);
      expect(outcome.info, 'generic');
    });

    test('sin fuga entre dos conversiones', () {
      final registry = ExtractorRegistryImpl([_TransformingExtractor()]);

      final first = registry.extractContent(
        '<p>uno</p>',
        originUrl: 'https://example.com/1',
      );
      final second = registry.extractContent(
        '<p>dos</p>',
        originUrl: 'https://desconocido.org/2',
      );

      expect(first.method, ExtractionMethod.siteSelector);
      expect(first.info, 'fake');
      expect(second.method, ExtractionMethod.generic);
      expect(second.info, 'generic');
    });
  });
}
