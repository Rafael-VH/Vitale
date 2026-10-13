// lib/features/convert/data/engines/mdream_js_engine.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/engine_info.dart';
import '../../domain/engines/markdown_engine.dart';

class MdreamJsEngine implements MarkdownEngine {
  @override
  EngineId get id => EngineId.mdreamJs;
  @override
  String get label => 'mdream.js (Web)';
  @override
  bool get isAvailable => false;

  @override
  Result<String> convert(String html) {
    return Err(EngineUnavailableFailure(message: 'mdream.js solo disponible en Web (JS interop).'));
  }
}
