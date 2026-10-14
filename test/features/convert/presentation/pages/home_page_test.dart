import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/presentation/controllers/convert_controller.dart';
import 'package:vitale/features/convert/presentation/pages/home_page.dart';

/// Controlador stub que construye un estado fijo para el test de widget.
class _StubConvertController extends ConvertController {
  _StubConvertController(this._buildResult);

  final FutureOr<ConversionResult?> Function() _buildResult;

  @override
  FutureOr<ConversionResult?> build() => _buildResult();
}

ConversionResult _result(String markdown) => ConversionResult(
      markdown: markdown,
      originalLength: 10,
      markdownLength: markdown.length,
      wasMhtml: false,
      wasFiltered: false,
      engineId: EngineId.html2md,
    );

Future<void> _pump(
  WidgetTester tester,
  ConvertController Function() create,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [convertControllerProvider.overrideWith(create)],
      child: const MaterialApp(home: HomePage()),
    ),
  );
}

void main() {
  testWidgets('idle: conserva el título y el hint, sin spinner', (tester) async {
    await _pump(tester, () => _StubConvertController(() => null));

    expect(find.text('Vitale'), findsOneWidget);
    expect(find.textContaining('Pegar HTML'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('loading: muestra el indicador de progreso', (tester) async {
    final completer = Completer<ConversionResult?>();
    await _pump(tester, () => _StubConvertController(() => completer.future));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error: muestra el mensaje de error', (tester) async {
    await _pump(
      tester,
      () => _StubConvertController(() => throw StateError('boom')),
    );
    await tester.pump();

    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('data: muestra el markdown resultante', (tester) async {
    await _pump(tester, () => _StubConvertController(() => _result('# hola')));
    await tester.pump();

    expect(find.textContaining('Markdown:'), findsOneWidget);
    expect(find.textContaining('# hola'), findsWidgets);
  });
}
