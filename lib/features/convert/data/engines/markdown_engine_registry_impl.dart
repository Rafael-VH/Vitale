// lib/features/convert/data/engines/markdown_engine_registry_impl.dart
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine_registry.dart';

class MarkdownEngineRegistryImpl implements MarkdownEngineRegistry {
  final List<MarkdownEngine> _engines;
  MarkdownEngineRegistryImpl(this._engines);

  @override
  List<MarkdownEngine> get engines => List.unmodifiable(_engines);
  @override
  List<MarkdownEngine> get availableEngines =>
      engines.where((e) => e.isAvailable).toList();

  @override
  MarkdownEngine? engineById(EngineId id) {
    for (final e in engines) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Result<EngineOutput> convert(String html, {EngineId? preferred}) {
    if (html.trim().isEmpty) return Err(EmptyInputFailure());
    final order = _buildOrder(preferred);
    if (order.isEmpty) return Err(EngineUnavailableFailure());
    final attempted = <EngineId>[];
    for (final e in order) {
      attempted.add(e.id);
      final r = e.convert(html);
      if (r is Ok<String> && r.value.trim().isNotEmpty) {
        return Ok(EngineOutput(markdown: r.value, engineId: e.id, attempted: attempted));
      }
    }
    return Err(AllEnginesFailedFailure());
  }

  List<MarkdownEngine> _buildOrder(EngineId? preferred) {
    final available = availableEngines;
    if (preferred == null) return available;
    final p = engineById(preferred);
    if (p == null || !p.isAvailable) return available;
    final rest = available.where((e) => e.id != p.id).toList();
    return [p, ...rest];
  }
}
