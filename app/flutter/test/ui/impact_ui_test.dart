import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/impact/models/beneficiary.dart';
import 'package:avijit_sahyog/features/impact/presentation/impact_page.dart';
import 'package:avijit_sahyog/features/impact/providers/beneficiaries_providers.dart';

const _items = [
  Beneficiary(
    id: 'b-1',
    name: 'Rahul Kumar',
    cause: 'Education',
    supportedYear: 2025,
    contributionAmount: 25000,
    story: 'Rahul continued his education.',
    organisationName: 'Demo Education Support Organisation',
  ),
  Beneficiary(
    id: 'b-2',
    name: 'Priya Sharma',
    cause: 'Healthcare',
    supportedYear: 2024,
    contributionAmount: 18000,
  ),
];

void main() {
  Widget app(List<Beneficiary> items) {
    return ProviderScope(
      overrides: [
        beneficiariesProvider.overrideWith((ref, query) async => items),
      ],
      child: const MaterialApp(home: ImpactPage()),
    );
  }

  testWidgets('impact page renders beneficiary cards and explorer controls',
      (tester) async {
    await tester.pumpWidget(app(_items));
    await tester.pumpAndSettle();

    expect(find.text('Our Impact'), findsOneWidget);
    expect(find.byKey(const ValueKey('beneficiary_search')), findsOneWidget);
    expect(find.byKey(const ValueKey('beneficiary_sort')), findsOneWidget);
    expect(find.text('Rahul Kumar'), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
    expect(find.text('Supported in 2025'), findsOneWidget);
    expect(find.text('₹25000 Contribution'), findsOneWidget);
    expect(find.text('View Story →'), findsNWidgets(2));
  });

  testWidgets('view story opens beneficiary detail page', (tester) async {
    await tester.pumpWidget(app(_items));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Story →').first);
    await tester.pumpAndSettle();

    expect(find.text('Impact Story'), findsOneWidget);
    expect(find.text('Rahul continued his education.'), findsOneWidget);
    expect(find.text('Supported through'), findsOneWidget);
    expect(find.text('Demo Education Support Organisation'), findsOneWidget);
  });

  testWidgets('beneficiary card renders network photo when photo URL is present',
      (tester) async {
    const item = Beneficiary(
      id: 'photo-1',
      name: 'Photo Beneficiary',
      cause: 'Education',
      supportedYear: 2025,
      contributionAmount: 100,
      photoUrl: 'https://example.com/photo.jpg',
    );

    await tester.pumpWidget(app([item]));
    await tester.pump();

    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('impact page shows empty state', (tester) async {
    await tester.pumpWidget(app(const []));
    await tester.pumpAndSettle();

    expect(find.text('No beneficiaries found.'), findsOneWidget);
  });
}
