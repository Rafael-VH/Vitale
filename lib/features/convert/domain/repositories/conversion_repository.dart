// lib/features/convert/domain/repositories/conversion_repository.dart
import '../../../../core/errors/result.dart';
import '../entities/conversion_result.dart';
import '../entities/engine_info.dart';
import '../entities/source_input.dart';

abstract class ConversionRepository {
  Future<Result<ConversionResult>> convert(SourceInput input, {EngineId? preferredEngine});
  String? extractHtmlFromMhtml(String raw);
  PreparedHtml prepareHtml(String rawInput);
}

class PreparedHtml {
  final String html;
  final bool wasMhtml;
  final bool wasFiltered;
  final int? mhtmlParts;
  final SiteKey siteKey;
  final String? originUrl;
  final ExtractionMethod method;
  final String? info;
  const PreparedHtml({
    required this.html,
    required this.wasMhtml,
    required this.wasFiltered,
    required this.siteKey,
    required this.method,
    this.mhtmlParts,
    this.originUrl,
    this.info,
  });
}
import '../entities/conversion_result.dart';
import '../entities/source_input.dart';
