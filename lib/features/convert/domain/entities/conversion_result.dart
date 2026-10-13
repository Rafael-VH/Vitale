// lib/features/convert/domain/entities/conversion_result.dart
import 'package:vitale/features/convert/domain/entities/engine_info.dart';

enum SiteKey {
  fanfiction,
  ao3,
  webnovel,
  royalroad,
  wikipedia,
  substack,
  blogger,
  unknown;
}

enum ExtractionMethod {
  siteSelector,
  siteCustom,
  generic,
  none,
}

class ConversionResult {
  final String markdown;
  final int originalLength;
  final int markdownLength;
  final bool wasMhtml;
  final bool wasFiltered;
  final int? mhtmlParts;
  final String? filterInfo;
  final SiteKey siteKey;
  final String? originUrl;
  final ExtractionMethod method;
  final EngineId engineId;

  const ConversionResult({
    required this.markdown,
    required this.originalLength,
    required this.markdownLength,
    required this.wasMhtml,
    required this.wasFiltered,
    required this.engineId,
    this.mhtmlParts,
    this.filterInfo,
    this.siteKey = SiteKey.unknown,
    this.originUrl,
    this.method = ExtractionMethod.none,
  });

  double get reductionPercent =>
      originalLength > 0 ? (100 - markdownLength / originalLength * 100) : 0;
}
