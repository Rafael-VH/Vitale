import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/features/convert/data/engines/html2md_engine.dart';
import 'package:vitale/core/errors/result.dart';

void main() {
  test('html2md convierte HTML básico', () {
    final e = Html2mdEngine();
    final r = e.convert('<p>Hola</p>');
    expect(r is Ok<String>, true);
    if (r is Ok<String>) {
      expect(r.value.contains('Hola'), true);
    }
  });
}
