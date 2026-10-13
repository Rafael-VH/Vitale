// lib/features/convert/data/repositories/conversion_repository_impl.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/conversion_result.dart';
import '../../domain/entities/engine_info.dart';
import '../../domain/entities/source_input.dart';
import '../../domain/engines/markdown_engine_registry.dart';
import '../../domain/extractors/extractor_registry.dart';
import '../../domain/repositories/conversion_repository.dart';
import '../datasources/mhtml_parser.dart';
import '../../../../core/utils/charset_helper.dart';

class ConversionRepositoryImpl implements ConversionRepository {
  final MarkdownEngineRegistry engineRegistry;
  final ExtractorRegistry extractorRegistry;
  final MhtmlParser mhtmlParser;
  ConversionRepositoryImpl({
    required this.engineRegistry,
    required this.extractorRegistry,
    MhtmlParser? mhtmlParser,
  }) : mhtmlParser = mhtmlParser ?? MhtmlParser();

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
    if (res is Err<EngineOutput>) return Err((res as Err<EngineOutput>).failure);
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
    return await CharsetHelper.decode(bytes);
  }
}
