// lib/features/convert/data/datasources/site_detector_datasource.dart

/// Fuente de datos que extrae la URL de origen (`originUrl`) de un documento.
///
/// Prueba en orden: `Snapshot-Content-Location`, `Content-Location` (solo
/// http/https), `<link rel="canonical">` y `og:url`. Devuelve `null` cuando no
/// encuentra ninguna señal. Funciona tanto para MHTML como para HTML pegado.
class SiteDetectorDataSource {
  static final RegExp _snapshot = RegExp(
    r'^Snapshot-Content-Location:[ \t]*(\S+)',
    multiLine: true,
    caseSensitive: false,
  );

  /// Cabecera `Content-Location` al inicio de línea; evita coincidir con texto
  /// del cuerpo o con prefijos de otra cabecera (p. ej. `X-Content-Location`).
  static final RegExp _contentLocation = RegExp(
    r'^Content-Location:[ \t]*(\S+)',
    multiLine: true,
    caseSensitive: false,
  );

  /// `rel` y `href` pueden aparecer en cualquier orden dentro de la etiqueta;
  /// los lookaheads lo garantizan sin fijar un orden concreto.
  static final RegExp _canonical = RegExp(
    r'''<link(?=[^>]*\brel=["']canonical["'])(?=[^>]*\bhref=["']([^"']+)["'])[^>]*>''',
    caseSensitive: false,
  );

  /// `property` y `content` pueden aparecer en cualquier orden dentro de la
  /// etiqueta `meta`.
  static final RegExp _ogUrl = RegExp(
    r'''<meta(?=[^>]*\bproperty=["']og:url["'])(?=[^>]*\bcontent=["']([^"']+)["'])[^>]*>''',
    caseSensitive: false,
  );

  static final RegExp _httpScheme = RegExp(r'^https?://', caseSensitive: false);

  /// Extrae la URL de origen de [raw]; devuelve `null` si no hay señal.
  String? extractOriginUrl(String raw) {
    if (raw.isEmpty) return null;

    final snapshot = _snapshot.firstMatch(raw);
    if (snapshot != null) return snapshot.group(1)!.trim();

    for (final match in _contentLocation.allMatches(raw)) {
      final value = match.group(1)!;
      if (_httpScheme.hasMatch(value)) return value.trim();
    }

    final canonical = _canonical.firstMatch(raw);
    if (canonical != null) return canonical.group(1);

    final ogUrl = _ogUrl.firstMatch(raw);
    if (ogUrl != null) return ogUrl.group(1);

    return null;
  }
}
