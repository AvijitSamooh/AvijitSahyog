import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/app.dart';

void main() {
  testWidgets('application renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AvijitSahyogApp());
    await tester.pumpAndSettle();

    expect(find.byType(AvijitSahyogApp), findsOneWidget);
  });
}
