import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/core/utils/charset_detector.dart';
import 'package:vitale/features/convert/data/datasources/mhtml_parser.dart';
import 'package:vitale/features/convert/data/datasources/site_detector_datasource.dart';
import 'package:vitale/features/convert/data/repositories/conversion_repository_impl.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/entities/source_input.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine_registry.dart';
import 'package:vitale/features/convert/domain/extractors/extract_outcome.dart';
import 'package:vitale/features/convert/domain/extractors/extractor_registry.dart';

/// Registro de extractores que registra los `originUrl` recibidos.
class _RecordingRegistry implements ExtractorRegistry {
  String? detectOriginUrl;
  String? extractOriginUrl;
  String? extractHtml;
  SiteKey key = SiteKey.unknown;
  ExtractOutcome outcome = const ExtractOutcome(
    html: '<p>filtrado</p>',
    method: ExtractionMethod.generic,
    info: 'generic',
  );

  @override
  SiteKey detectSiteKey(String? originUrl, String html) {
    detectOriginUrl = originUrl;
    return key;
  }

  @override
  ExtractOutcome extractContent(String html, {String? originUrl}) {
    extractOriginUrl = originUrl;
    extractHtml = html;
    return outcome;
  }
}

class _FakeEngineRegistry implements MarkdownEngineRegistry {
  bool called = false;

  @override
  List<MarkdownEngine> get engines => const [];

  @override
  List<MarkdownEngine> get availableEngines => const [];

  @override
  MarkdownEngine? engineById(EngineId id) => null;

  @override
  Result<EngineOutput> convert(String html, {EngineId? preferred}) {
    called = true;
    return const Ok(EngineOutput(markdown: '# md', engineId: EngineId.html2md));
  }
}

class _FakeCharsetDetector implements CharsetDetector {
  int calls = 0;

  @override
  Future<String> decode(List<int> bytes) async {
    calls++;
    return '<p>archivo</p>';
  }
}

void main() {
  late _RecordingRegistry registry;
  late _FakeEngineRegistry engines;
  late _FakeCharsetDetector charset;
  late ConversionRepositoryImpl repo;

  setUp(() {
    registry = _RecordingRegistry();
    engines = _FakeEngineRegistry();
    charset = _FakeCharsetDetector();
    repo = ConversionRepositoryImpl(
      engineRegistry: engines,
      extractorRegistry: registry,
      mhtmlParser: MhtmlParser(),
      siteDetector: SiteDetectorDataSource(),
      charsetDetector: charset,
    );
  });

  test('propaga el originUrl a la detección y a la extracción', () async {
    const raw = 'Snapshot-Content-Location: https://archiveofourown.org/works/1\n'
        '<html><body>hola</body></html>';

    final res = await repo.convert(const PastedInput(raw));

    expect(res, isA<Ok<ConversionResult>>());
    expect(registry.detectOriginUrl, 'https://archiveofourown.org/works/1');
    expect(registry.extractOriginUrl, 'https://archiveofourown.org/works/1');
  });

  test('resultado refleja method y filterInfo del ExtractOutcome', () async {
    registry.outcome = const ExtractOutcome(
      html: '<article>x</article>',
      method: ExtractionMethod.siteSelector,
      info: 'ao3',
    );
    registry.key = SiteKey.ao3;

    final res = await repo.convert(const PastedInput('<html>x</html>'));

    final value = (res as Ok<ConversionResult>).value;
    expect(value.method, ExtractionMethod.siteSelector);
    expect(value.filterInfo, 'ao3');
    expect(value.siteKey, SiteKey.ao3);
    expect(value.wasFiltered, isTrue);
  });

  test('origen no detectable → Ok con siteKey unknown y originUrl null', () async {
    final res = await repo.convert(const PastedInput('<html><body>x</body></html>'));

    final value = (res as Ok<ConversionResult>).value;
    expect(value.siteKey, SiteKey.unknown);
    expect(value.originUrl, isNull);
    expect(registry.detectOriginUrl, isNull);
  });

  test('usa el CharsetDetector inyectado para FileInput', () async {
    final res = await repo.convert(
      const FileInput(path: 'a.mhtml', filename: 'a.mhtml', bytes: [1, 2, 3]),
    );

    expect(res, isA<Ok<ConversionResult>>());
    expect(charset.calls, 1);
  });

  test('entrada vacía → Err(EmptyInputFailure) sin invocar el motor', () async {
    final res = await repo.convert(const PastedInput('   '));

    expect(res, isA<Err<ConversionResult>>());
    expect((res as Err<ConversionResult>).failure, isA<EmptyInputFailure>());
    expect(engines.called, isFalse);
  });

  test('extracción vacía → Err(EmptyInputFailure) sin invocar el motor', () async {
    registry.outcome = const ExtractOutcome(
      html: '   ',
      method: ExtractionMethod.generic,
      info: 'generic',
    );

    final res = await repo.convert(const PastedInput('<html>x</html>'));

    expect(res, isA<Err<ConversionResult>>());
    expect((res as Err<ConversionResult>).failure, isA<EmptyInputFailure>());
    expect(engines.called, isFalse);
  });
}
