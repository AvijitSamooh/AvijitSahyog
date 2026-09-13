import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/features/causes/models/organisation.dart';
import 'package:avijit_sahyog/features/causes/presentation/organisation_detail_page.dart';

void main() {
  const organisation = Organisation(
    id: 'org-1',
    slug: 'seva-trust',
    name: 'Seva Trust',
    description: 'Serving the community.',
    city: 'Pune',
    state: 'Maharashtra',
    gallery: [
      'https://images.example.com/one.webp',
      'https://images.example.com/two.webp',
    ],
  );

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(
      AppShellScope(
        onLocaleChanged: (_) {},
        navigation: AppNavigationController(),
        child: const MaterialApp(
          home: OrganisationDetailPage(organisation: organisation),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('displays organisation details and admin-provided gallery', (tester) async {
    await pumpSubject(tester);

    expect(find.text('Seva Trust'), findsOneWidget);
    expect(find.text('Serving the community.'), findsOneWidget);
    expect(find.text('Pune, Maharashtra'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('opens the selected gallery image in the full-screen viewer', (tester) async {
    await pumpSubject(tester);

    await tester.tap(find.byType(InkWell).first);
    await tester.pump();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
