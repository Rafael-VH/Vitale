// lib/features/convert/domain/usecases/convert_html_to_markdown.dart
import '../../../../core/errors/result.dart';
import '../entities/conversion_result.dart';
import '../entities/engine_info.dart';
import '../entities/source_input.dart';
import '../repositories/conversion_repository.dart';

class ConvertHtmlToMarkdown {
  final ConversionRepository repository;
  ConvertHtmlToMarkdown(this.repository);

  Future<Result<ConversionResult>> call(SourceInput input, {EngineId? preferredEngine}) =>
      repository.convert(input, preferredEngine: preferredEngine);
}
