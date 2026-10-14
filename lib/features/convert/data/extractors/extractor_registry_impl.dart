// lib/features/convert/data/extractors/extractor_registry_impl.dart
import 'package:vitale/features/convert/data/extractors/generic_extractor.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/extractors/extract_outcome.dart';
import 'package:vitale/features/convert/domain/extractors/extractor_registry.dart';
import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';

/// Implementación del registro de extractores.
///
/// Detecta el sitio derivándolo de los `hostPatterns` de los extractores
/// registrados y devuelve un [ExtractOutcome] inmutable, sin estado mutable
/// compartido entre conversiones.
class ExtractorRegistryImpl implements ExtractorRegistry {
  final List<SiteExtractor> _extractors;
  final GenericExtractor _generic = GenericExtractor();

  ExtractorRegistryImpl(this._extractors);

  @override
  SiteKey detectSiteKey(String? originUrl, String html) {
    final host = _host(originUrl);
    if (host == null || host.isEmpty) return SiteKey.unknown;
    for (final e in _extractors) {
      if (_matches(host, e.hostPatterns)) return e.siteKey;
    }
    return SiteKey.unknown;
  }

  @override
  ExtractOutcome extractContent(String html, {String? originUrl}) {
    final host = _host(originUrl);
    if (host != null && host.isNotEmpty) {
      for (final e in _extractors) {
        if (!_matches(host, e.hostPatterns)) continue;
        try {
          final out = e.extract(html, originUrl: originUrl);
          if (out.isNotEmpty && out != html) {
            return ExtractOutcome(
              html: out,
              method: e.extractionMethod,
              info: e.siteName,
            );
          }
          return _genericOutcome(html, originUrl);
        } catch (_) {
          // Extractor fallido: continuar con el siguiente o el genérico.
        }
      }
    }
    return _genericOutcome(html, originUrl);
  }

  ExtractOutcome _genericOutcome(String html, String? originUrl) {
    return ExtractOutcome(
      html: _generic.extract(html, originUrl: originUrl),
      method: ExtractionMethod.generic,
      info: 'generic',
    );
  }

  String? _host(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      final u = Uri.parse(url);
      return u.host.toLowerCase();
    } catch (_) {
      return null;
    }
  }

  bool _matches(String host, Set<String> patterns) {
    for (final p in patterns) {
      final lp = p.toLowerCase();
      if (host == lp || host.endsWith('.$lp')) return true;
    }
    return false;
  }
}
