// lib/features/convert/data/repositories/conversion_repository_impl.dart
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/core/utils/charset_detector.dart';
import 'package:vitale/features/convert/data/datasources/mhtml_parser.dart';
import 'package:vitale/features/convert/data/datasources/site_detector_datasource.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/entities/source_input.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine_registry.dart';
import 'package:vitale/features/convert/domain/extractors/extractor_registry.dart';
import 'package:vitale/features/convert/domain/repositories/conversion_repository.dart';

/// Implementación del repositorio de conversión.
///
/// Orquesta el pipeline MHTML/HTML → `originUrl` → detección de sitio →
/// extracción → Markdown. Todas sus dependencias se inyectan desde el
/// composition root; la capa data no construye defaults ocultos.
class ConversionRepositoryImpl implements ConversionRepository {
  final MarkdownEngineRegistry engineRegistry;
  final ExtractorRegistry extractorRegistry;
  final MhtmlParser mhtmlParser;
  final SiteDetectorDataSource siteDetector;
  final CharsetDetector charsetDetector;

  ConversionRepositoryImpl({
    required this.engineRegistry,
    required this.extractorRegistry,
    required this.mhtmlParser,
    required this.siteDetector,
    required this.charsetDetector,
  });

  @override
  Future<Result<ConversionResult>> convert(
    SourceInput input, {
    EngineId? preferredEngine,
  }) async {
    final raw = await _readRaw(input);
    if (raw.trim().isEmpty) return Err(EmptyInputFailure());
    final htmlFromMhtml = extractHtmlFromMhtml(raw);
    final baseHtml = htmlFromMhtml ?? raw;
    final originUrl = siteDetector.extractOriginUrl(raw);
    final siteKey = extractorRegistry.detectSiteKey(originUrl, baseHtml);
    final outcome = extractorRegistry.extractContent(baseHtml, originUrl: originUrl);
    final filteredHtml = outcome.html;
    if (filteredHtml.trim().isEmpty) return Err(EmptyInputFailure());
    final res = engineRegistry.convert(filteredHtml, preferred: preferredEngine);
    if (res is Err<EngineOutput>) return Err(res.failure);
    final out = (res as Ok<EngineOutput>).value;
    return Ok(ConversionResult(
      markdown: out.markdown,
      originalLength: filteredHtml.length,
      markdownLength: out.markdown.length,
      wasMhtml: htmlFromMhtml != null,
      wasFiltered: filteredHtml != baseHtml,
      engineId: out.engineId,
      siteKey: siteKey,
      originUrl: originUrl,
      method: outcome.method,
      filterInfo: outcome.info,
    ));
  }

  @override
  String? extractHtmlFromMhtml(String raw) => mhtmlParser.extractHtml(raw);

  @override
  PreparedHtml prepareHtml(String rawInput) {
    final htmlFromMhtml = extractHtmlFromMhtml(rawInput);
    final baseHtml = htmlFromMhtml ?? rawInput;
    final originUrl = siteDetector.extractOriginUrl(rawInput);
    final outcome = extractorRegistry.extractContent(baseHtml, originUrl: originUrl);
    final filtered = outcome.html;
    return PreparedHtml(
      html: filtered,
      wasMhtml: htmlFromMhtml != null,
      wasFiltered: filtered != baseHtml,
      siteKey: extractorRegistry.detectSiteKey(originUrl, baseHtml),
      originUrl: originUrl,
      method: outcome.method,
      info: outcome.info,
    );
  }

  Future<String> _readRaw(SourceInput input) async {
    return switch (input) {
      PastedInput(text: final t) => t,
      FileInput(bytes: final b) => await _decode(b),
    };
  }

  Future<String> _decode(List<int> bytes) async {
    return await charsetDetector.decode(bytes);
  }
}
