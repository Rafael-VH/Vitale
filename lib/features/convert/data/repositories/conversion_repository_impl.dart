// lib/features/convert/data/repositories/conversion_repository_impl.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/conversion_result.dart';
import '../../domain/entities/engine_info.dart';
import '../../domain/entities/source_input.dart';
import '../../domain/engines/markdown_engine_registry.dart';
import '../../domain/repositories/conversion_repository.dart';

class ConversionRepositoryImpl implements ConversionRepository {
  final MarkdownEngineRegistry engineRegistry;
  ConversionRepositoryImpl({required this.engineRegistry});

  @override
  Future<Result<ConversionResult>> convert(SourceInput input, {EngineId? preferredEngine}) async {
    final html = _extractHtml(input);
    if (html.trim().isEmpty) return Err(EmptyInputFailure());
    final res = engineRegistry.convert(html, preferred: preferredEngine);
    if (res is Err<EngineOutput>) {
      return Err((res as Err<EngineOutput>).failure);
    }
    final out = (res as Ok<EngineOutput>).value;
    return Ok(ConversionResult(
      markdown: out.markdown,
      originalLength: html.length,
      markdownLength: out.markdown.length,
      wasMhtml: false,
      wasFiltered: false,
      engineId: out.engineId,
      siteKey: SiteKey.unknown,
      method: ExtractionMethod.none,
    ));
  }

  @override
  String? extractHtmlFromMhtml(String raw) => null;

  @override
  PreparedHtml prepareHtml(String rawInput) {
    return PreparedHtml(
      html: rawInput,
      wasMhtml: false,
      wasFiltered: false,
      siteKey: SiteKey.unknown,
      method: ExtractionMethod.none,
    );
  }

  String _extractHtml(SourceInput input) {
    return switch (input) {
      PastedInput(text: final t) => t,
      FileInput(bytes: final b) => String.fromCharCodes(b),
    };
  }
}
