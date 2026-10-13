// lib/features/convert/domain/entities/engine_info.dart
enum EngineId { html2md, mdreamJs, htmlToMarkdownRs }

class EngineOutput {
  final String markdown;
  final EngineId engineId;
  final List<EngineId> attempted;
  const EngineOutput({
    required this.markdown,
    required this.engineId,
    this.attempted = const [],
  });
}
