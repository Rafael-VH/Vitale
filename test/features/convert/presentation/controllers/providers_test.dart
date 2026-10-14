import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/features/convert/data/engines/html2md_engine.dart';
import 'package:vitale/features/convert/data/engines/html_to_markdown_rs_engine.dart';
import 'package:vitale/features/convert/data/engines/mdream_js_engine.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine.dart';
import 'package:vitale/features/convert/domain/usecases/convert_html_to_markdown.dart';
import 'package:vitale/features/convert/presentation/controllers/providers.dart';

void main() {
  group('providers', () {
    test('extractorRegistryProvider registra Ao3 y Fanfiction', () {
      final container = ProviderContainer.test();
      final registry = container.read(extractorRegistryProvider);

      expect(
        registry.detectSiteKey('https://archiveofourown.org/works/1', '<p>x</p>'),
        SiteKey.ao3,
      );
      expect(
        registry.detectSiteKey('https://www.fanfiction.net/s/1', '<p>x</p>'),
        SiteKey.fanfiction,
      );
    });

    test('enginesProvider: Html2md primero y stubs no disponibles', () {
      final container = ProviderContainer.test();
      final engines = container.read(enginesProvider);

      expect(engines.first, isA<Html2mdEngine>());
      expect(engines.first.isAvailable, isTrue);

      final stubs = <MarkdownEngine>[
        ...engines.whereType<MdreamJsEngine>(),
        ...engines.whereType<HtmlToMarkdownRsEngine>(),
      ];
      expect(stubs, isNotEmpty);
      expect(stubs.every((e) => !e.isAvailable), isTrue);
    });

    test('convertHtmlToMarkdownProvider resuelve', () {
      final container = ProviderContainer.test();

      expect(
        container.read(convertHtmlToMarkdownProvider),
        isA<ConvertHtmlToMarkdown>(),
      );
    });
  });
}
