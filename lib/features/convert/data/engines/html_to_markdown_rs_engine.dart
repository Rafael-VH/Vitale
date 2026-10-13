// lib/features/convert/data/engines/html_to_markdown_rs_engine.dart
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine.dart';

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
