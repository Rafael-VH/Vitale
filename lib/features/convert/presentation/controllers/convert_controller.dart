// lib/features/convert/presentation/controllers/convert_controller.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vitale/core/errors/result.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/entities/source_input.dart';
import 'package:vitale/features/convert/presentation/controllers/providers.dart';

/// Controlador del estado de conversión de la pantalla principal.
///
/// El estado `idle` se representa como `AsyncData(null)`. El controlador solo
/// traduce/delega: lee el caso de uso y mapea el `Result` a `AsyncValue`.
class ConvertController extends AsyncNotifier<ConversionResult?> {
  @override
  FutureOr<ConversionResult?> build() => null;

  /// Ejecuta la conversión de [input] y actualiza el estado resultante.
  Future<void> convert(SourceInput input, {EngineId? preferredEngine}) async {
    state = const AsyncValue.loading();
    final result = await ref
        .read(convertHtmlToMarkdownProvider)
        .call(input, preferredEngine: preferredEngine);
    state = switch (result) {
      Ok(:final value) => AsyncValue.data(value),
      Err(:final failure) =>
        AsyncValue.error(failure.message, StackTrace.current),
    };
  }
}

/// Provider del controlador de conversión.
final convertControllerProvider =
    AsyncNotifierProvider<ConvertController, ConversionResult?>(
  ConvertController.new,
);
