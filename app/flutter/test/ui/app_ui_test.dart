import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avijit_sahyog/app.dart';
import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/causes/models/cause.dart';
import 'package:avijit_sahyog/features/causes/models/organisation.dart';
import 'package:avijit_sahyog/features/causes/presentation/causes_page.dart';
import 'package:avijit_sahyog/features/causes/presentation/cause_detail_page.dart';
import 'package:avijit_sahyog/features/causes/providers/causes_providers.dart';
import 'package:avijit_sahyog/features/donations/data/donations_repository.dart';
import 'package:avijit_sahyog/features/donations/models/create_donation.dart';
import 'package:avijit_sahyog/features/donations/presentation/donation_page.dart';
import 'package:avijit_sahyog/features/donations/providers/donation_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

const _organisation = Organisation(
  id: 'org-1',
  slug: 'seva-trust',
  name: 'Seva Trust',
  description: 'A sample organisation used by the UI tests.',
  city: 'Pune',
  state: 'Maharashtra',
);

const _organisationTwo = Organisation(
  id: 'org-2',
  slug: 'shiksha-trust',
  name: 'Shiksha Trust',
  description: 'A second sample organisation used by allocation tests.',
  city: 'Mumbai',
  state: 'Maharashtra',
);

const _organisations = [_organisation, _organisationTwo];

const _cause = Cause(
  id: 'cause-1',
  slug: 'education',
  name: 'Education',
  description: 'Support education initiatives.',
  organisations: _organisations,
);

class _FakeDonationsRepository extends DonationsRepository {
  _FakeDonationsRepository() : super(ApiClient());

  CreateDonation? lastDonation;

  @override
  Future<Map<String, dynamic>> createDonation(CreateDonation input) async {
    lastDonation = input;
    return {'id': 'donation-1', 'status': 'PENDING'};
  }


}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Widget? home,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: ThemeData(useMaterial3: true),
          home: home ?? const AvijitSahyogApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  Future<void> pumpDonationPage(
    WidgetTester tester, {
    List<Cause> causes = const [_cause],
    List<Override> overrides = const [],
    String? initialCauseId = 'cause-1',
  }) async {
    await pumpApp(
      tester,
      home: DonationPage(initialCauseId: initialCauseId),
      overrides: [
        causesProvider('en').overrideWith((ref) async => causes),
        ...overrides,
      ],
    );
    expect(find.byType(DonationPage), findsOneWidget);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> enterVisibleText(
    WidgetTester tester,
    Finder finder,
    String value,
  ) async {
    await tester.tap(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  Future<void> advanceToDistribution(WidgetTester tester) async {
    await tapVisible(
      tester,
      find.byKey(const ValueKey('donation_primary_action')),
    );
    expect(
      find.byKey(const ValueKey('donation_amount_input')),
      findsOneWidget,
    );
  }

  Future<void> advanceToReview(WidgetTester tester) async {
    await tapVisible(
      tester,
      find.byKey(const ValueKey('donation_amount_1000')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('donation_primary_action')),
    );
    expect(find.text('₹ 1000.00'), findsWidgets);
  }

  testWidgets('home page renders the cause-centric entry point', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();
    expect(find.byType(AvijitSahyogApp), findsOneWidget);
    expect(find.text('Welcome to Avijit Sahyog'), findsOneWidget);
  });

  testWidgets('home hero loads Maharaj Ji image asset', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('impact navigation opens the real impact explorer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See Our Impact'));
    await tester.pumpAndSettle();
    expect(find.text('Our Impact'), findsOneWidget);
  });

  testWidgets('language selector opens and shows all supported languages', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
  });

  testWidgets('causes page displays mocked causes', (tester) async {
    await pumpApp(tester, home: const CausesPage(), overrides: [
      causesProvider('en').overrideWith((ref) async => const [_cause]),
    ]);
    expect(find.text('Education'), findsWidgets);
  });

  testWidgets('selecting a cause opens cause details', (tester) async {
    await pumpApp(tester, home: const CausesPage(), overrides: [
      causesProvider('en').overrideWith((ref) async => const [_cause]),
      causeProvider((slug: 'education', languageCode: 'en')).overrideWith((ref) async => _cause),
    ]);
    await tester.tap(find.text('Education').first);
    await tester.pumpAndSettle();
    expect(find.byType(CauseDetailPage), findsOneWidget);
  });

  testWidgets('step 1 requires at least one selected cause', (tester) async {
    await pumpDonationPage(tester, initialCauseId: null);
    final action = find.byKey(const ValueKey('donation_primary_action'));
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
  });

  testWidgets('step 1 moves from causes to distribution', (tester) async {
    await pumpDonationPage(tester);
    await advanceToDistribution(tester);
    expect(find.text('Choose Amount'), findsOneWidget);
    expect(find.text('Share Across Causes'), findsOneWidget);
  });

  testWidgets('step 2 requires amount and 100 percent allocation', (tester) async {
    await pumpDonationPage(tester);
    await advanceToDistribution(tester);
    final action = find.byKey(const ValueKey('donation_primary_action'));
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('donation_amount_1000')),
    );
    final updatedAction =
        find.byKey(const ValueKey('donation_primary_action'));
    expect(tester.widget<FilledButton>(updatedAction).onPressed, isNotNull);
  });

  testWidgets('back navigation returns to cause selection', (tester) async {
    await pumpDonationPage(tester);
    await advanceToDistribution(tester);
    await tapVisible(tester, find.byKey(const ValueKey('donation_back')));
    expect(find.byKey(const ValueKey('donation_cause_cause-1')), findsOneWidget);
  });

  testWidgets('multi-cause allocation reaches review with calculated amounts', (tester) async {
    await pumpDonationPage(tester, causes: const [
        _cause,
        Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
      ]);
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await advanceToDistribution(tester);
    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));
    await enterVisibleText(tester, find.byKey(const ValueKey('donation_percentage_cause-1')), '70');
    await enterVisibleText(tester, find.byKey(const ValueKey('donation_percentage_cause-2')), '30');
    expect(find.text('Total allocation: 100%'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('donation_primary_action')));
    expect(find.text('₹ 700.00'), findsOneWidget);
    expect(find.text('₹ 300.00'), findsOneWidget);
  });

  testWidgets('step 2 cannot continue when allocations do not total 100 percent', (tester) async {
    await pumpDonationPage(tester, causes: const [
        _cause,
        Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
      ]);
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await advanceToDistribution(tester);
    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));
    await enterVisibleText(tester, find.byKey(const ValueKey('donation_percentage_cause-1')), '70');
    await enterVisibleText(tester, find.byKey(const ValueKey('donation_percentage_cause-2')), '20');
    final action = find.byKey(const ValueKey('donation_primary_action'));
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
  });

  testWidgets('review submits existing donation allocation contract', (tester) async {
    final repository = _FakeDonationsRepository();
    await pumpDonationPage(tester, overrides: [
      donationRepositoryProvider.overrideWithValue(repository),
    ]);
    await advanceToDistribution(tester);
    await advanceToReview(tester);
    await tapVisible(tester, find.byKey(const ValueKey('donation_primary_action')));
    expect(repository.lastDonation, isNotNull);
    expect(repository.lastDonation!.amount, '1000.00');
    expect(repository.lastDonation!.allocations, hasLength(1));
    expect(repository.lastDonation!.allocations.single.causeId, 'cause-1');
    expect(repository.lastDonation!.allocations.single.amount, '1000.00');
    expect(find.text(l10n(tester).donationCreatedTitle), findsOneWidget);
  });

}
