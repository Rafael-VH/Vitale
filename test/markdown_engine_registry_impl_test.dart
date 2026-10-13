import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/data/engines/html2md_engine.dart';
import 'package:vitale/features/convert/data/engines/markdown_engine_registry_impl.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';

void main() {
  test('cascada usa html2md por defecto', () {
    final reg = MarkdownEngineRegistryImpl([Html2mdEngine()]);
    final r = reg.convert('<p>Test</p>');
    expect(r is Ok<EngineOutput>, true);
    if (r is Ok<EngineOutput>) {
      expect(r.value.engineId, EngineId.html2md);
    }
  });

  test('empty devuelve Err', () {
    final reg = MarkdownEngineRegistryImpl([Html2mdEngine()]);
    final r = reg.convert('  ');
    expect(r is Err<EngineOutput>, true);
  });
}
