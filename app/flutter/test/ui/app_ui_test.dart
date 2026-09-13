import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avijit_sahyog/app.dart';
import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/core/widgets/app_navigation_bar.dart';
import 'package:avijit_sahyog/features/causes/models/cause.dart';
import 'package:avijit_sahyog/features/causes/models/organisation.dart';
import 'package:avijit_sahyog/features/causes/presentation/causes_page.dart';
import 'package:avijit_sahyog/features/home/home_page.dart';
import 'package:avijit_sahyog/features/impact/models/beneficiary.dart';
import 'package:avijit_sahyog/features/impact/presentation/impact_page.dart';
import 'package:avijit_sahyog/features/impact/providers/beneficiaries_providers.dart';
import 'package:avijit_sahyog/features/causes/presentation/cause_detail_page.dart';
import 'package:avijit_sahyog/features/causes/providers/causes_providers.dart';
import 'package:avijit_sahyog/features/donations/presentation/donation_page.dart';
import 'package:avijit_sahyog/features/auth/presentation/login_page.dart';
import 'package:avijit_sahyog/features/auth/presentation/profile_page.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_portal_page.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_dashboard_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_dashboard_providers.dart';
import 'package:avijit_sahyog/features/admin/models/admin_dashboard_summary.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_beneficiaries_page.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_causes_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_beneficiaries_providers.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_organisations_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_organisations_providers.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_causes_providers.dart';
import 'package:avijit_sahyog/features/auth/models/app_user.dart';
import 'package:avijit_sahyog/features/auth/models/auth_state.dart';
import 'package:avijit_sahyog/features/auth/providers/auth_providers.dart';
import 'package:avijit_sahyog/features/auth/data/auth_repository.dart';
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
        child: AppShellScope(
          onLocaleChanged: (_) {},
          navigation: AppNavigationController(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: ThemeData(useMaterial3: true),
            home: home ?? const AvijitSahyogApp(),
          ),
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
  }) async {
    await pumpApp(
      tester,
      home: const DonationPage(initialCauseId: 'cause-1'),
      overrides: [
        causesProvider('en').overrideWith((ref) async => causes),
        ...overrides,
      ],
    );
    expect(find.byType(DonationPage), findsOneWidget);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pump();
    }
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> enterVisibleText(
    WidgetTester tester,
    Finder finder,
    String value,
  ) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  testWidgets('home page renders the cause-centric entry point', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    expect(find.byType(AvijitSahyogApp), findsOneWidget);
    expect(find.byKey(const ValueKey('app_settings_menu')), findsOneWidget);
    expect(find.text('Welcome to Avijit Sahyog'), findsOneWidget);
    expect(find.text('Explore Causes'), findsWidgets);
    expect(find.text('See Our Impact'), findsOneWidget);
  });

  testWidgets('public home exposes login from the shared settings menu', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    expect(find.byKey(const ValueKey('app_settings_menu')), findsOneWidget);
    expect(find.text('Explore Causes'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('app_settings_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('authenticated admin can see the admin portal entry', (tester) async {
    await pumpApp(
      tester,
      home: const ProfilePage(),
      overrides: [
        authProvider.overrideWith(
          (ref) => _AuthenticatedAdminController(),
        ),
      ],
    );

    expect(find.byKey(const ValueKey('admin_portal_entry')), findsOneWidget);
  });

  testWidgets('authenticated admin can open the admin portal', (tester) async {
    await pumpApp(
      tester,
      home: const ProfilePage(),
      overrides: [
        authProvider.overrideWith(
          (ref) => _AuthenticatedAdminController(),
        ),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('admin_portal_entry')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminPortalPage), findsOneWidget);
    expect(find.text('Manage causes'), findsOneWidget);
  });

  testWidgets('admin portal opens dashboard with operational summary', (tester) async {
    await pumpApp(
      tester,
      home: const AdminPortalPage(),
      overrides: [
        adminDashboardProvider.overrideWith((ref) async => const AdminDashboardSummary(
          causes: AdminDashboardMetric(total: 3, active: 2, inactive: 1),
          organisations: AdminDashboardMetric(total: 4, active: 4, inactive: 0),
          beneficiaries: AdminDashboardMetric(total: 8, active: 7, inactive: 1),
        )),
      ],
    );

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(find.text('Operational overview'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('admin portal exposes cause management workflow', (tester) async {
    await pumpApp(
      tester,
      home: const AdminPortalPage(),
      overrides: [
        adminCausesProvider.overrideWith(
          (ref) async => const [],
        ),
      ],
    );

    await tester.tap(find.text('Manage causes'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminCausesPage), findsOneWidget);
    expect(find.byKey(const ValueKey('admin_create_cause')), findsOneWidget);
  });

  testWidgets('admin portal exposes beneficiary management workflow', (tester) async {
    await pumpApp(
      tester,
      home: const AdminPortalPage(),
      overrides: [
        adminBeneficiariesProvider.overrideWith((ref) async => const []),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('admin_manage_beneficiaries')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminBeneficiariesPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin_create_beneficiary')),
      findsOneWidget,
    );
  });

  testWidgets('admin portal exposes organisation management workflow', (tester) async {
    await pumpApp(
      tester,
      home: const AdminPortalPage(),
      overrides: [
        adminOrganisationsProvider.overrideWith((ref) async => const []),
      ],
    );

    await tester.tap(find.text('Manage organisations'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminOrganisationsPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin_create_organisation')),
      findsOneWidget,
    );
  });

  testWidgets('home hero loads Maharaj Ji image asset', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('impact navigation opens the real impact explorer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pumpAndSettle();
    final impactButton = find.text('See Our Impact');
    await tester.ensureVisible(impactButton);
    await tester.tap(impactButton);
    await tester.pumpAndSettle();
    expect(find.text('Our Impact'), findsOneWidget);
    expect(find.text('Search by name'), findsOneWidget);
  });

  testWidgets('Causes tab keeps a single shell header and no nested app bar', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
        beneficiariesProvider((search: '', sort: null))
            .overrideWith((ref) async => const []),
      ],
    );

    final navigation = AppShellScope.of(
      tester.element(find.byType(HomePage)),
    ).navigation;
    navigation.select(1);
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CausesPage),
        matching: find.byType(AppBar),
      ),
      findsNothing,
      reason: 'CausesPage must remain body-only; HomePage owns the single app bar.',
    );
  });

  testWidgets('Impact tab keeps a single shell header and no nested app bar', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
        beneficiariesProvider((search: '', sort: null))
            .overrideWith((ref) async => const <Beneficiary>[]),
      ],
    );

    final navigation = AppShellScope.of(
      tester.element(find.byType(HomePage)),
    ).navigation;
    navigation.select(2);
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomePage),
        matching: find.byType(AppBar),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ImpactPage),
        matching: find.byType(AppBar),
      ),
      findsNothing,
      reason: 'ImpactPage must remain body-only; HomePage owns the single app bar.',
    );
  });

  testWidgets('language selector opens and shows all supported languages', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('app_settings_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Marathi'), findsOneWidget);
    expect(find.text('Gujarati'), findsOneWidget);
  });

  testWidgets('language selector changes the app locale', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('app_settings_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hindi'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('selected_locale'), 'hi');
  });

  testWidgets('causes page displays mocked causes', (tester) async {
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
      ],
    );

    expect(find.text('Education'), findsWidgets);
    expect(find.text('Support education initiatives.'), findsOneWidget);
    expect(find.byIcon(Icons.volunteer_activism_rounded), findsOneWidget);
  });

  testWidgets('selecting a cause opens cause details', (tester) async {
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => _cause),
      ],
    );

    await tester.tap(find.text('Education').first);
    await tester.pumpAndSettle();

    expect(find.byType(CauseDetailPage), findsOneWidget);
    expect(find.text('Support education initiatives.'), findsWidgets);
    expect(find.text('Seva Trust'), findsOneWidget);
  });

  testWidgets('cause details display organisation and location', (tester) async {
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => _cause),
      ],
    );

    expect(find.text('Seva Trust'), findsOneWidget);
    expect(find.text('Pune, Maharashtra'), findsOneWidget);
  });
}
