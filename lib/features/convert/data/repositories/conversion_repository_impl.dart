// lib/features/convert/data/repositories/conversion_repository_impl.dart
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/entities/source_input.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine_registry.dart';
import 'package:vitale/features/convert/domain/extractors/extractor_registry.dart';
import 'package:vitale/features/convert/domain/repositories/conversion_repository.dart';
import 'package:vitale/features/convert/data/datasources/mhtml_parser.dart';
import 'package:vitale/core/utils/charset_detector.dart';
import 'package:vitale/core/utils/charset_detector_impl.dart';

class ConversionRepositoryImpl implements ConversionRepository {
  final MarkdownEngineRegistry engineRegistry;
  final ExtractorRegistry extractorRegistry;
  final MhtmlParser mhtmlParser;
  final CharsetDetector charsetDetector;
  ConversionRepositoryImpl({
    required this.engineRegistry,
    required this.extractorRegistry,
    MhtmlParser? mhtmlParser,
    CharsetDetector? charsetDetector,
  })  : mhtmlParser = mhtmlParser ?? MhtmlParser(),
        charsetDetector = charsetDetector ?? CharsetDetectorImpl();

  @override
  Future<Result<ConversionResult>> convert(SourceInput input, {EngineId? preferredEngine}) async {
    final raw = await _readRaw(input);
    if (raw.trim().isEmpty) return Err(EmptyInputFailure());
    final htmlFromMhtml = extractHtmlFromMhtml(raw);
    final baseHtml = htmlFromMhtml ?? raw;
    final siteKey = extractorRegistry.detectSiteKey(null, baseHtml);
    final filteredHtml = extractorRegistry.extractContent(baseHtml, originUrl: null);
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
      method: extractorRegistry.getLastMethod(),
      filterInfo: extractorRegistry.getLastFilterInfo(),
    ));
  }

  @override
  String? extractHtmlFromMhtml(String raw) => mhtmlParser.extractHtml(raw);

  @override
  PreparedHtml prepareHtml(String rawInput) {
    final htmlFromMhtml = extractHtmlFromMhtml(rawInput);
    final baseHtml = htmlFromMhtml ?? rawInput;
    final filtered = extractorRegistry.extractContent(baseHtml);
    return PreparedHtml(
      html: filtered,
      wasMhtml: htmlFromMhtml != null,
      wasFiltered: filtered != baseHtml,
      siteKey: extractorRegistry.detectSiteKey(null, baseHtml),
      method: extractorRegistry.getLastMethod(),
      info: extractorRegistry.getLastFilterInfo(),
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
