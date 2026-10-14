import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/features/convert/data/datasources/site_detector_datasource.dart';

void main() {
  final detector = SiteDetectorDataSource();

  group('extractOriginUrl', () {
    test('1) prioriza Snapshot-Content-Location', () {
      const raw = 'Snapshot-Content-Location: https://archiveofourown.org/works/1\r\n'
          'Content-Location: https://otra.example/x\r\n';

      expect(detector.extractOriginUrl(raw), 'https://archiveofourown.org/works/1');
    });

    test('2) usa Content-Location cuando es http/https', () {
      const raw = 'Content-Type: text/html\r\n'
          'Content-Location: https://www.fanfiction.net/s/42\r\n';

      expect(detector.extractOriginUrl(raw), 'https://www.fanfiction.net/s/42');
    });

    test('ignora Content-Location no http/https y sigue con la siguiente señal', () {
      const raw = 'Content-Location: cid:parte-1\r\n'
          '<link rel="canonical" href="https://example.com/canonico">';

      expect(detector.extractOriginUrl(raw), 'https://example.com/canonico');
    });

    test('3) usa <link rel="canonical">', () {
      const raw = '<head><link rel="canonical" href="https://example.com/art"></head>';

      expect(detector.extractOriginUrl(raw), 'https://example.com/art');
    });

    test('4) usa og:url como última señal', () {
      const raw = '<meta property="og:url" content="https://example.com/og">';

      expect(detector.extractOriginUrl(raw), 'https://example.com/og');
    });

    test('sin ninguna señal devuelve null', () {
      const raw = '<html><body><p>sin url</p></body></html>';

      expect(detector.extractOriginUrl(raw), isNull);
    });

    test('entrada vacía devuelve null', () {
      expect(detector.extractOriginUrl(''), isNull);
    });

    test('ignora Content-Location embebido en el cuerpo del documento', () {
      const raw = '<html><body>\n'
          '<p>Content-Location: http://decoy.example/inyectado</p>\n'
          '</body></html>';

      expect(detector.extractOriginUrl(raw), isNull);
    });

    test('ignora X-Content-Location (el prefijo no es la cabecera real)', () {
      const raw = 'X-Content-Location: http://decoy.example/x\r\n'
          'Content-Type: text/html\r\n';

      expect(detector.extractOriginUrl(raw), isNull);
    });

    test('usa Content-Location real al inicio de línea (no rompe el happy path)', () {
      const raw = 'Content-Type: text/html\r\n'
          'Content-Location: http://real.example/page\r\n';

      expect(detector.extractOriginUrl(raw), 'http://real.example/page');
    });

    test('5) usa canonical aunque href venga antes que rel', () {
      const raw = '<head><link href="https://example.com/a" rel="canonical"></head>';

      expect(detector.extractOriginUrl(raw), 'https://example.com/a');
    });

    test('6) usa og:url aunque content venga antes que property', () {
      const raw = '<meta content="https://example.com/og2" property="og:url">';

      expect(detector.extractOriginUrl(raw), 'https://example.com/og2');
    });
  });
}
