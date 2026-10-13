// lib/features/convert/domain/engines/markdown_engine.dart
import '../../../../core/errors/result.dart';
import '../entities/engine_info.dart';

abstract class MarkdownEngine {
  EngineId get id;
  String get label;
  bool get isAvailable;
  Result<String> convert(String html);
}
