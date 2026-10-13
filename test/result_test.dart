import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/core/errors/failures.dart';
import 'package:vitale/core/errors/result.dart';

void main() {
  test('Ok expone el valor', () {
    const Result<int> r = Ok(42);
    expect(r, isA<Ok<int>>());
    expect((r as Ok<int>).value, 42);
  });

  test('Err expone el failure', () {
    const Result<int> r = Err(EmptyInputFailure());
    expect(r, isA<Err<int>>());
    expect((r as Err<int>).failure, isA<EmptyInputFailure>());
  });

  test('EmptyInputFailure tiene mensaje por defecto', () {
    const f = EmptyInputFailure();
    expect(f.message, isNotEmpty);
  });
}
