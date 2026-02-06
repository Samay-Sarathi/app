import 'package:flutter_test/flutter_test.dart';
import 'package:lifeline/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeLineApp());
    await tester.pump();
    expect(find.text('LIFELINE'), findsOneWidget);
  });
}
