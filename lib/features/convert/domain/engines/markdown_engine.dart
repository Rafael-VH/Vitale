// lib/features/convert/domain/engines/markdown_engine.dart
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';

abstract class MarkdownEngine {
  EngineId get id;
  String get label;
  bool get isAvailable;
  Result<String> convert(String html);
}
