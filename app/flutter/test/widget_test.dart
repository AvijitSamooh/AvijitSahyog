import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avijit_sahyog/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('application renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AvijitSahyogApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AvijitSahyogApp), findsOneWidget);
  });
}
