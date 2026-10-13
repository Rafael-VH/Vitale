// lib/features/convert/presentation/controllers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mhtml_parser.dart';
import '../../data/engines/html2md_engine.dart';
import '../../data/engines/markdown_engine_registry_impl.dart';
import '../../data/extractors/extractor_registry_impl.dart';
import '../../data/repositories/conversion_repository_impl.dart';
import '../../domain/engines/markdown_engine.dart';
import '../../domain/engines/markdown_engine_registry.dart';
import '../../domain/extractors/extractor_registry.dart';
import '../../domain/repositories/conversion_repository.dart';
import '../../domain/usecases/convert_html_to_markdown.dart';

final mhtmlParserProvider = Provider<MhtmlParser>((ref) => MhtmlParser());
final enginesProvider = Provider<List<MarkdownEngine>>((ref) => [Html2mdEngine()]);
final engineRegistryProvider = Provider<MarkdownEngineRegistry>((ref) => MarkdownEngineRegistryImpl(ref.read(enginesProvider)));
final extractorRegistryProvider = Provider<ExtractorRegistry>((ref) => ExtractorRegistryImpl(const []));
final conversionRepositoryProvider = Provider<ConversionRepository>((ref) {
  return ConversionRepositoryImpl(
    engineRegistry: ref.read(engineRegistryProvider),
    extractorRegistry: ref.read(extractorRegistryProvider),
    mhtmlParser: ref.read(mhtmlParserProvider),
  );
});
final convertHtmlToMarkdownProvider = Provider<ConvertHtmlToMarkdown>((ref) => ConvertHtmlToMarkdown(ref.read(conversionRepositoryProvider)));
