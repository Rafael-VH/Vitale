// lib/features/convert/presentation/controllers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/engines/html2md_engine.dart';
import '../../data/engines/markdown_engine_registry_impl.dart';
import '../../domain/engines/markdown_engine.dart';
import '../../domain/engines/markdown_engine_registry.dart';
import '../../domain/usecases/convert_html_to_markdown.dart';
import '../../data/repositories/conversion_repository_impl.dart';
import '../../domain/repositories/conversion_repository.dart';

final enginesProvider = Provider<List<MarkdownEngine>>((ref) {
  return [
    Html2mdEngine(),
  ];
});

final engineRegistryProvider = Provider<MarkdownEngineRegistry>((ref) {
  return MarkdownEngineRegistryImpl(ref.read(enginesProvider));
});

final conversionRepositoryProvider = Provider<ConversionRepository>((ref) {
  return ConversionRepositoryImpl(
    engineRegistry: ref.read(engineRegistryProvider),
  );
});

final convertHtmlToMarkdownProvider = Provider<ConvertHtmlToMarkdown>((ref) {
  return ConvertHtmlToMarkdown(ref.read(conversionRepositoryProvider));
});
