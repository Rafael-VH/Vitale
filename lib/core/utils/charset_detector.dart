// lib/core/utils/charset_detector.dart
abstract class CharsetDetector {
  /// Decodifica bytes a texto detectando el charset.
  String decode(List<int> bytes);
}
