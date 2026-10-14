import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/extractors/extract_outcome.dart';

void main() {
  group('ExtractOutcome', () {
    test('expone html, method e info', () {
      const outcome = ExtractOutcome(
        html: '<p>x</p>',
        method: ExtractionMethod.siteSelector,
        info: 'ao3',
      );

      expect(outcome.html, '<p>x</p>');
      expect(outcome.method, ExtractionMethod.siteSelector);
      expect(outcome.info, 'ao3');
    });

    test('info es opcional y por defecto null', () {
      const outcome = ExtractOutcome(
        html: '<p>x</p>',
        method: ExtractionMethod.generic,
      );

      expect(outcome.info, isNull);
      expect(outcome.method, ExtractionMethod.generic);
    });
  });
}
