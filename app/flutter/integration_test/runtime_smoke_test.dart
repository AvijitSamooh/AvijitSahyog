import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flutter integration runtime can render and persist native preferences', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('integration_test_probe', 'ok');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Avijit Sahyog integration smoke')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Avijit Sahyog integration smoke'), findsOneWidget);
    expect(preferences.getString('integration_test_probe'), 'ok');
  });
}
