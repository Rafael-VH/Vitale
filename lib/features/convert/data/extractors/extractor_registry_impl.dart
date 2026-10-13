// lib/features/convert/data/extractors/extractor_registry_impl.dart
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/extractors/extractor_registry.dart';
import 'package:vitale/features/convert/domain/extractors/site_extractor.dart';
import 'package:vitale/features/convert/data/extractors/generic_extractor.dart';

class ExtractorRegistryImpl implements ExtractorRegistry {
  final List<SiteExtractor> _extractors;
  final GenericExtractor _generic = GenericExtractor();
  ExtractionMethod _lastMethod = ExtractionMethod.none;
  String? _lastFilterInfo;

  ExtractorRegistryImpl(this._extractors);

  @override
  ExtractionMethod getLastMethod() => _lastMethod;
  @override
  String? getLastFilterInfo() => _lastFilterInfo;

  @override
  SiteKey detectSiteKey(String? originUrl, String html) {
    final host = _host(originUrl);
    if (host == null || host.isEmpty) return SiteKey.unknown;
    if (_matches(host, {'fanfiction.net'})) return SiteKey.fanfiction;
    if (_matches(host, {'archiveofourown.org', 'archiveofourown.com'})) return SiteKey.ao3;
    if (_matches(host, {'webnovel.com'})) return SiteKey.webnovel;
    if (_matches(host, {'royalroad.com', 'royalroadl.com'})) return SiteKey.royalroad;
    if (_matches(host, {'wikipedia.org', 'wikisource.org'})) return SiteKey.wikipedia;
    if (_matches(host, {'substack.com'})) return SiteKey.substack;
    if (_matches(host, {'blogger.com', 'blogspot.com'})) return SiteKey.blogger;
    return SiteKey.unknown;
  }

  @override
  String extractContent(String html, {String? originUrl}) {
    final host = _host(originUrl);
    if (host != null && host.isNotEmpty) {
      for (final e in _extractors) {
        if (_matches(host, e.hostPatterns)) {
          try {
            final out = e.extract(html, originUrl: originUrl);
            if (out.isNotEmpty && out != html) {
              _lastMethod = e.extractionMethod;
              _lastFilterInfo = e.siteName;
            } else {
              _lastMethod = ExtractionMethod.generic;
            }
            return out;
          } catch (_) {
            // fall through
          }
        }
      }
    }
    _lastMethod = ExtractionMethod.generic;
    _lastFilterInfo = 'generic';
    return _generic.extract(html, originUrl: originUrl);
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
