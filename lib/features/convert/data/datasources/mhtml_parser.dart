// lib/features/convert/data/datasources/mhtml_parser.dart
class MhtmlParser {
  static const String _boundaryMarker = 'boundary=';

  String? extractHtml(String raw) {
    if (raw.isEmpty) return null;
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final idx = text.indexOf(_boundaryMarker);
    if (idx < 0) return null;
    final startQuote = text.indexOf('"', idx);
    final endQuote = startQuote >= 0 ? text.indexOf('"', startQuote + 1) : -1;
    String? boundary;
    if (startQuote >= 0 && endQuote > startQuote) {
      boundary = text.substring(startQuote + 1, endQuote);
    } else {
      final semi = text.indexOf(';', idx);
      final end = semi >= 0 ? text.indexOf('\n', semi) : -1;
      if (end > semi) {
        boundary = text.substring(semi + 1, end).trim();
      }
    }
    if (boundary == null || boundary.isEmpty) return null;
    final parts = text.split('--$boundary');
    if (parts.length < 2) return null;
    for (final p in parts.skip(1)) {
      final lower = p.toLowerCase();
      if (lower.contains('content-type: text/html')) {
        final body = _splitBody(p);
        if (body != null && body.isNotEmpty) return body;
      }
    }
    for (final p in parts.skip(1)) {
      final body = _splitBody(p);
      if (body != null && body.contains('<html')) return body;
    }
    return null;
  }

  String? _splitBody(String part) {
    final sep = part.indexOf('\n\n');
    if (sep >= 0) return part.substring(sep + 2);
    final sep2 = part.indexOf('\n\r\n');
    if (sep2 >= 0) return part.substring(sep2 + 3);
    return part;
  }
}
