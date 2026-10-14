import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/entities/source_input.dart';
import 'package:vitale/features/convert/domain/repositories/conversion_repository.dart';
import 'package:vitale/features/convert/domain/usecases/convert_html_to_markdown.dart';
import 'package:vitale/features/convert/presentation/controllers/convert_controller.dart';
import 'package:vitale/features/convert/presentation/controllers/providers.dart';

class _FakeRepository implements ConversionRepository {
  Result<ConversionResult> Function()? onConvert;

  @override
  Future<Result<ConversionResult>> convert(
    SourceInput input, {
    EngineId? preferredEngine,
  }) async =>
      onConvert!();

  @override
  String? extractHtmlFromMhtml(String raw) => null;

  @override
  PreparedHtml prepareHtml(String rawInput) => throw UnimplementedError();
}

ConversionResult _result(String markdown) => ConversionResult(
      markdown: markdown,
      originalLength: 10,
      markdownLength: markdown.length,
      wasMhtml: false,
      wasFiltered: false,
      engineId: EngineId.html2md,
    );

void main() {
  late _FakeRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepository();
    container = ProviderContainer.test(overrides: [
      convertHtmlToMarkdownProvider.overrideWithValue(ConvertHtmlToMarkdown(repo)),
    ]);
  });

  test('idle → AsyncData(null)', () {
    final state = container.read(convertControllerProvider);

    expect(state, isA<AsyncData<ConversionResult?>>());
    expect(state.value, isNull);
  });

  test('Ok → AsyncData(result)', () async {
    final result = _result('# ok');
    repo.onConvert = () => Ok(result);

    await container
        .read(convertControllerProvider.notifier)
        .convert(const PastedInput('<p>x</p>'));

    final state = container.read(convertControllerProvider);
    expect(state, isA<AsyncData<ConversionResult?>>());
    expect(state.value, same(result));
  });

  test('Err → AsyncError(message)', () async {
    repo.onConvert = () => Err(const ConversionFailure('boom'));

    await container
        .read(convertControllerProvider.notifier)
        .convert(const PastedInput('<p>x</p>'));

    final state = container.read(convertControllerProvider);
    expect(state, isA<AsyncError<ConversionResult?>>());
    expect(state.error, 'boom');
  });

  test('segunda conversión reemplaza el estado (sin fuga)', () async {
    final first = _result('# uno');
    repo.onConvert = () => Ok(first);
    await container
        .read(convertControllerProvider.notifier)
        .convert(const PastedInput('uno'));
    expect(container.read(convertControllerProvider).value, same(first));

    final second = _result('# dos');
    repo.onConvert = () => Ok(second);
    await container
        .read(convertControllerProvider.notifier)
        .convert(const PastedInput('dos'));
    expect(container.read(convertControllerProvider).value, same(second));
  });
}
