// lib/features/convert/domain/engines/markdown_engine_registry.dart
import '../../../../core/errors/result.dart';
import '../entities/engine_info.dart';
import 'markdown_engine.dart';

abstract class MarkdownEngineRegistry {
  List<MarkdownEngine> get engines;
  List<MarkdownEngine> get availableEngines;
  MarkdownEngine? engineById(EngineId id);
  Result<EngineOutput> convert(String html, {EngineId? preferred});
}
