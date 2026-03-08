import 'package:flutter_test/flutter_test.dart';
import 'package:lifeline/core/providers/settings_provider.dart';
import 'package:lifeline/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    final settings = SettingsProvider();
    await settings.init();
    await tester.pumpWidget(LifeLineApp(settings: settings));
    await tester.pump();
    expect(find.text('SAMAY SARTHI'), findsOneWidget);
  });
}
