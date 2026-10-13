// lib/core/utils/charset_detector.dart
/// Detección y decodificación de charset desde bytes crudos.
///
/// Contrato asíncrono: el fallback para charsets no-UTF-8 usa
/// `package:charset_converter`, cuya API es `Future<String>`.
abstract class CharsetDetector {
  /// Decodifica bytes a texto detectando el charset
  /// (UTF-8 → charsets conocidos → UTF-8 tolerante).
  Future<String> decode(List<int> bytes);
}
