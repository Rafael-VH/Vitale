import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/data/engines/html2md_engine.dart';
import 'package:vitale/features/convert/data/engines/markdown_engine_registry_impl.dart';
import 'package:vitale/features/convert/data/engines/mdream_js_engine.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/engines/markdown_engine.dart';

/// Motor disponible que siempre falla, para forzar el agotamiento de la cascada.
class _FailingEngine implements MarkdownEngine {
  @override
  EngineId get id => EngineId.htmlToMarkdownRs;

  @override
  String get label => 'failing';

  @override
  bool get isAvailable => true;

  @override
  Result<String> convert(String html) => Err(ConversionFailure());
}

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

  test('motor preferido no disponible → usa el siguiente disponible', () {
    final reg = MarkdownEngineRegistryImpl([Html2mdEngine(), MdreamJsEngine()]);
    final r = reg.convert('<p>Test</p>', preferred: EngineId.mdreamJs);
    expect(r is Ok<EngineOutput>, true);
    if (r is Ok<EngineOutput>) {
      expect(r.value.engineId, EngineId.html2md);
    }
  });

  test('sin motores disponibles → Err(EngineUnavailableFailure)', () {
    final reg = MarkdownEngineRegistryImpl([MdreamJsEngine()]);
    final r = reg.convert('<p>Test</p>');
    expect(r, isA<Err<EngineOutput>>());
    expect((r as Err<EngineOutput>).failure, isA<EngineUnavailableFailure>());
  });

  test('todos los motores fallan → Err(AllEnginesFailedFailure)', () {
    final reg = MarkdownEngineRegistryImpl([_FailingEngine()]);
    final r = reg.convert('<p>Test</p>');
    expect(r, isA<Err<EngineOutput>>());
    expect((r as Err<EngineOutput>).failure, isA<AllEnginesFailedFailure>());
  });
}
