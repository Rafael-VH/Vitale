// lib/features/convert/presentation/controllers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vitale/core/utils/charset_detector.dart';
import 'package:vitale/core/utils/charset_detector_impl.dart';
import 'package:vitale/features/convert/data/datasources/mhtml_parser.dart';
import 'package:vitale/features/convert/data/datasources/site_detector_datasource.dart';
import 'package:vitale/features/convert/data/engines/html2md_engine.dart';
import 'package:vitale/features/convert/data/engines/html_to_markdown_rs_engine.dart';
import 'package:vitale/features/convert/data/engines/markdown_engine_registry_impl.dart';
import 'package:vitale/features/convert/data/engines/mdream_js_engine.dart';
import 'package:vitale/features/convert/data/extractors/ao3_extractor.dart';
import 'package:vitale/features/convert/data/extractors/extractor_registry_impl.dart';
import 'package:vitale/features/convert/data/extractors/fanfiction_extractor.dart';
import 'package:vitale/features/convert/data/repositories/conversion_repository_impl.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine_registry.dart';
import 'package:vitale/features/convert/domain/extractors/extractor_registry.dart';
import 'package:vitale/features/convert/domain/repositories/conversion_repository.dart';
import 'package:vitale/features/convert/domain/usecases/convert_html_to_markdown.dart';

// Composition root del pipeline de conversión.
//
// Arma el grafo real de dependencias (charset, MHTML, detección de sitio,
// extractores, motores y caso de uso). Los motores no disponibles se registran
// igualmente: la cascada los salta vía `isAvailable`.

/// Parser de MHTML.
final mhtmlParserProvider = Provider<MhtmlParser>((ref) => MhtmlParser());

/// Detector de la URL de origen.
final siteDetectorProvider =
    Provider<SiteDetectorDataSource>((ref) => SiteDetectorDataSource());

/// Detector/decodificador de charset para entradas de archivo.
final charsetDetectorProvider =
    Provider<CharsetDetector>((ref) => CharsetDetectorImpl());

/// Motores de conversión, en orden de la cascada.
final enginesProvider = Provider<List<MarkdownEngine>>(
  (ref) => [Html2mdEngine(), MdreamJsEngine(), HtmlToMarkdownRsEngine()],
);

/// Registro de motores con la cascada de conversión.
final engineRegistryProvider = Provider<MarkdownEngineRegistry>(
  (ref) => MarkdownEngineRegistryImpl(ref.read(enginesProvider)),
);

/// Registro de extractores específicos de sitio.
final extractorRegistryProvider = Provider<ExtractorRegistry>(
  (ref) => ExtractorRegistryImpl([Ao3Extractor(), FanfictionExtractor()]),
);

/// Repositorio de conversión con todas sus dependencias inyectadas.
final conversionRepositoryProvider = Provider<ConversionRepository>((ref) {
  return ConversionRepositoryImpl(
    engineRegistry: ref.read(engineRegistryProvider),
    extractorRegistry: ref.read(extractorRegistryProvider),
    mhtmlParser: ref.read(mhtmlParserProvider),
    siteDetector: ref.read(siteDetectorProvider),
    charsetDetector: ref.read(charsetDetectorProvider),
  );
});

/// Caso de uso de conversión HTML/MHTML → Markdown.
final convertHtmlToMarkdownProvider = Provider<ConvertHtmlToMarkdown>(
  (ref) => ConvertHtmlToMarkdown(ref.read(conversionRepositoryProvider)),
);
