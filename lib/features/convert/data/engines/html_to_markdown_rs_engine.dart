// lib/features/convert/data/engines/html_to_markdown_rs_engine.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/engine_info.dart';
import '../../domain/engines/markdown_engine.dart';

class HtmlToMarkdownRsEngine implements MarkdownEngine {
  @override
  EngineId get id => EngineId.htmlToMarkdownRs;
  @override
  String get label => 'html_to_markdown (FFI)';
  @override
  bool get isAvailable => false;

  @override
  Result<String> convert(String html) {
    return Err(EngineUnavailableFailure( 'html_to_markdown.rs solo disponible con FFI (Android/iOS).'));
  }
}
