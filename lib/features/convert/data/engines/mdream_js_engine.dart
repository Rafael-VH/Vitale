// lib/features/convert/data/engines/mdream_js_engine.dart
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine.dart';

class MdreamJsEngine implements MarkdownEngine {
  @override
  EngineId get id => EngineId.mdreamJs;
  @override
  String get label => 'mdream.js (Web)';
  @override
  bool get isAvailable => false;

  @override
  Result<String> convert(String html) {
    return Err(EngineUnavailableFailure('mdream.js solo disponible en Web (JS interop).'));
  }
}
