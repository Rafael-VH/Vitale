// lib/core/utils/charset_detector_impl.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';

import 'package:vitale/core/utils/charset_detector.dart';

class CharsetDetectorImpl implements CharsetDetector {
  static const _candidates = [
    'windows-1252',
    'iso-8859-1',
    'shift_jis',
    'euc-jp',
    'gbk',
    'big5',
    'koi8-r',
  ];

  @override
  Future<String> decode(List<int> bytes) async {
    // 1. UTF-8 estricto cubre UTF-8 y ASCII; lanza si no lo es.
    try {
      return utf8.decode(bytes);
    } on FormatException {
      // sigue con los charsets conocidos
    }

    // 2. Charsets no-UTF-8 vía charset_converter.
    for (final c in _candidates) {
      try {
        final decoded =
            await CharsetConverter.decode(c, Uint8List.fromList(bytes));
        if (decoded.isNotEmpty) return decoded;
      } catch (_) {
        // charset no soportado en esta plataforma: probar el siguiente
      }
    }

    // 3. Último recurso: UTF-8 tolerante (reemplaza bytes inválidos).
    return utf8.decode(bytes, allowMalformed: true);
  }
}
