// lib/features/convert/data/engines/html2md_engine.dart
import 'package:html2md/html2md.dart' as html2md;

import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine.dart';

class Html2mdEngine implements MarkdownEngine {
  @override
  EngineId get id => EngineId.html2md;
  @override
  String get label => 'html2md (Dart puro)';
  @override
  bool get isAvailable => true;

  @override
  Result<String> convert(String html) {
    try {
      final md = html2md.convert(html, styleOptions: const {
        'headingStyle': 'atx',
        'hr': '- - -',
        'bulletListMarker': '-',
        'codeBlockStyle': 'fenced',
        'fence': '```',
        'emDelimiter': '*',
        'strongDelimiter': '**',
        'linkStyle': 'inlined',
      });
      if (md.trim().isEmpty) return Err(ConversionFailure());
      return Ok(md);
    } catch (_) {
      return Err(ConversionFailure());
    }
  }
}
