// lib/core/utils/charset_detector_impl.dart
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';

import 'charset_detector.dart';

class CharsetDetectorImpl implements CharsetDetector {
  @override
  String decode(List<int> bytes) {
    return decodeAsync(bytes);
  }

  Future<String> decodeAsync(List<int> bytes) async {
    try {
      final s = String.fromCharCodes(bytes);
      if (!_looksUtf8Corrupted(s)) return s;
    } catch (_) {}
    try {
      final candidates = ['windows-1252', 'iso-8859-1', 'shift_jis', 'euc-jp', 'gbk', 'big5', 'koi8-r'];
      for (final c in candidates) {
        try {
          final decoded = await CharsetConverter.decode(c, Uint8List.fromList(bytes));
          if (decoded.isNotEmpty) return decoded;
        } catch (_) {}
      }
    } catch (_) {}
    try {
      return String.fromCharCodes(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  static bool _looksUtf8Corrupted(String s) {
    return s.contains('\uFFFD');
  }
}
