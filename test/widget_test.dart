import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitale/main.dart';

void main() {
  testWidgets('Vitale app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VitaleApp()));
    expect(find.text('Vitale'), findsOneWidget);
    expect(find.textContaining('Pegar HTML'), findsOneWidget);
  });
}
