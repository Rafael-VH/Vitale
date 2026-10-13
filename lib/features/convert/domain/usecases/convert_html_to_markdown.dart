// lib/features/convert/domain/usecases/convert_html_to_markdown.dart
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/entities/source_input.dart';
import 'package:vitale/features/convert/domain/repositories/conversion_repository.dart';

class ConvertHtmlToMarkdown {
  final ConversionRepository repository;
  ConvertHtmlToMarkdown(this.repository);

  Future<Result<ConversionResult>> call(SourceInput input, {EngineId? preferredEngine}) =>
      repository.convert(input, preferredEngine: preferredEngine);
}
