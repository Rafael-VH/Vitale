import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/main.dart';

void main() {
  testWidgets('Vitale app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const VitaleApp());
    expect(find.text('Vitale'), findsOneWidget);
    expect(find.text('Vitale - Conversión HTML/MHTML a Markdown'), findsOneWidget);
  });
}
