import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avijit_sahyog/app.dart';
import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/core/theme/app_theme.dart';
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
import 'package:avijit_sahyog/features/admin/models/admin_beneficiary.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_beneficiaries_page.dart';
import 'package:avijit_sahyog/features/applications/presentation/applications_page.dart';
import 'package:avijit_sahyog/features/applications/presentation/admin_applications_page.dart';
import 'package:avijit_sahyog/features/applications/models/application_window.dart';
import 'package:avijit_sahyog/features/applications/models/application_rule.dart';
import 'package:avijit_sahyog/features/applications/providers/help_applications_providers.dart';
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
  testWidgets('service window messages keep the offline interval start and end ordered', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();

    final localizations = AppLocalizations.of(tester.element(find.byType(SizedBox)))!;
    expect(
      localizations.serviceUnavailableMessage('8:00 AM', '9:00 PM'),
      'The service is offline from 9:00 PM to 8:00 AM. You can still view available content, but actions that need the backend are temporarily unavailable.',
    );
    expect(
      localizations.serviceUnavailableBanner('8:00 AM', '9:00 PM'),
      'Backend service is offline from 9:00 PM to 8:00 AM.',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Widget? home,
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
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
            locale: locale,
            theme: AppTheme.light(),
            home: home ?? const AvijitSahyogApp(splashDuration: Duration.zero),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final anyScaffold = find.byWidgetPredicate((widget) => widget is Scaffold);
  final anyAppBar = find.byWidgetPredicate((widget) => widget is AppBar);

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(anyScaffold.first))!;

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
    await tester.pump();
    await tester.tap(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  testWidgets('home page matches the approved Avijit Samuh reference', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp(splashDuration: Duration.zero)));
    await tester.pumpAndSettle();

    expect(find.byType(AvijitSahyogApp), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Avijit Sahyog'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
    expect(find.text('Cooperation'), findsOneWidget);
    expect(find.text('Recognition'), findsOneWidget);
    expect(find.text('Applications'), findsOneWidget);
    expect(find.text('Information'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('home exposes the assistance applications workflow', (tester) async {
    await pumpApp(tester);

    final applicationsEntry = find.byKey(const ValueKey('home_applications'));
    await tester.ensureVisible(applicationsEntry);
    await tester.pump();
    await tester.tap(applicationsEntry);
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationsPage), findsOneWidget);
    expect(find.text('Please sign in to submit an application.'), findsOneWidget);
  });

  testWidgets('Pratibha Samman form collects certificate and student details', (tester) async {
    final open = ApplicationWindow.fromJson({
      'type': 'PRATIBHA_SAMMAN',
      'startsAt': '2026-10-01T10:00:00.000Z',
      'registrationEndsAt': '2026-10-20T23:59:59.000Z',
      'eventAt': '2026-10-25T00:00:00.000Z',
      'closedAt': null,
      'status': 'OPEN',
      'canApply': true,
    });
    final rule = ApplicationRule.fromJson({
      'id': 'rule-1',
      'type': 'PRATIBHA_SAMMAN',
      'text': 'This recognition is for the 2025-26 batch only.',
      'displayOrder': 1,
    });

    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpApp(
      tester,
      home: const HelpApplicationFormPage(type: 'PRATIBHA_SAMMAN'),
      overrides: [
        applicationWindowsProvider.overrideWith((ref) async => [open]),
        applicationRulesProvider(
          (type: 'PRATIBHA_SAMMAN', language: 'en'),
        ).overrideWith((ref) async => [rule]),
      ],
    );

    await tester.pumpAndSettle();
    for (final key in const [
      'pratibha_mother_name',
      'pratibha_father_name',
      'pratibha_date_of_birth',
      'pratibha_class_standard',
      'pratibha_school_institute',
      'pratibha_certificate_photo',
      'pratibha_certificate_camera',
      'pratibha_accomplishments',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.byType(CheckboxListTile), findsOneWidget);
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(
      checkbox.fillColor?.resolve({MaterialState.selected}),
      Colors.green.shade600,
    );
    expect(
      checkbox.checkColor,
      Colors.white,
    );
  });

  testWidgets('certificate upload progress widget renders visible progress feedback', (tester) async {
    await pumpApp(
      tester,
      home: const ApplicationUploadProgress(
        label: 'Uploading image...',
        completed: 0,
        total: 1,
      ),
    );

    expect(find.byKey(const ValueKey('application_upload_progress')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Uploading image... 0/1'), findsOneWidget);
  });

  testWidgets('application rules render translated text, order, dates, and no implementation placeholders in every supported language', (tester) async {
    final open = ApplicationWindow.fromJson({
      'type': 'PRATIBHA_SAMMAN',
      'startsAt': '2026-10-01T10:00:00.000Z',
      'registrationEndsAt': '2026-10-20T23:59:59.000Z',
      'eventAt': '2026-10-25T00:00:00.000Z',
      'closedAt': null,
      'status': 'OPEN',
      'canApply': true,
    });

    const translations = {
      'en': 'Only students from Pune are eligible.',
      'hi': 'केवल पुणे के विद्यार्थी पात्र हैं।',
      'mr': 'फक्त पुण्यातील विद्यार्थी पात्र आहेत.',
      'gu': 'માત્ર પુણેના વિદ્યાર્થીઓ જ પાત્ર છે.',
    };

    for (final entry in translations.entries) {
      final rules = [
        ApplicationRule.fromJson({
          'id': 'rule-${entry.key}-1',
          'type': 'PRATIBHA_SAMMAN',
          'text': entry.value,
          'displayOrder': 1,
        }),
        ApplicationRule.fromJson({
          'id': 'rule-${entry.key}-2',
          'type': 'PRATIBHA_SAMMAN',
          'text': 'This is a deliberately long rule with multiple clauses that must remain readable when rendered in the application form.\nThe second line is part of the same rule.',
          'displayOrder': 2,
        }),
      ];

      await pumpApp(
        tester,
        locale: Locale(entry.key),
        home: const HelpApplicationFormPage(type: 'PRATIBHA_SAMMAN'),
        overrides: [
          applicationWindowsProvider.overrideWith((ref) async => [open]),
          applicationRulesProvider.overrideWith((ref, key) async => rules),
        ],
      );

      final localizations = l10n(tester);
      final registrationDate = MaterialLocalizations.of(
        tester.element(anyScaffold.first),
      ).formatMediumDate(open.registrationEndsAt!.toLocal());
      final eventDate = MaterialLocalizations.of(
        tester.element(anyScaffold.first),
      ).formatMediumDate(open.eventAt!.toLocal());

      expect(find.text('1. ${entry.value}'), findsOneWidget);
      expect(find.textContaining('2. This is a deliberately long rule'), findsOneWidget);
      expect(find.textContaining(localizations.registrationLastDate), findsOneWidget);
      expect(find.textContaining(registrationDate), findsOneWidget);
      expect(find.textContaining(localizations.eventDate), findsOneWidget);
      expect(find.textContaining(eventDate), findsOneWidget);

      expect(find.textContaining(r'\${entry.key + 1}.'), findsNothing);
      expect(find.textContaining(r'\${rule.text}'), findsNothing);
      expect(find.textContaining(r'\${l10n.registrationLastDate}'), findsNothing);
      expect(find.textContaining(r'\${l10n.eventDate}'), findsNothing);
    }
  });

  testWidgets('application page explains a scheduled and closed application window', (tester) async {
    final scheduled = ApplicationWindow.fromJson({
      'type': 'EDUCATION_ASSISTANCE',
      'startsAt': '2026-10-05T10:00:00.000Z',
      'closedAt': null,
      'status': 'SCHEDULED',
      'canApply': false,
    });
    final closed = ApplicationWindow.fromJson({
      'type': 'MEDICAL_HELP',
      'startsAt': '2026-09-01T10:00:00.000Z',
      'closedAt': '2026-09-29T10:00:00.000Z',
      'status': 'CLOSED',
      'canApply': false,
    });
    final open = ApplicationWindow.fromJson({
      'type': 'PRATIBHA_SAMMAN',
      'startsAt': '2026-09-01T10:00:00.000Z',
      'closedAt': null,
      'status': 'OPEN',
      'canApply': true,
    });

    await pumpApp(
      tester,
      home: const ApplicationsPage(),
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedAdminController()),
        applicationWindowsProvider.overrideWith((ref) async => [scheduled, closed, open]),
        myHelpApplicationsProvider.overrideWith((ref) async => const []),
      ],
    );

    expect(find.textContaining('Applications will start from'), findsOneWidget);
    expect(find.text('Applications are no longer being accepted.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('application_education')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Applications will start from'), findsWidgets);
  });

  testWidgets('admin applications page scrolls to window controls and application list', (tester) async {
    final scheduled = ApplicationWindow.fromJson({
      'type': 'EDUCATION_ASSISTANCE',
      'startsAt': '2026-10-05T10:00:00.000Z',
      'closedAt': null,
      'status': 'SCHEDULED',
      'canApply': false,
    });
    final open = ApplicationWindow.fromJson({
      'type': 'MEDICAL_HELP',
      'startsAt': '2026-09-01T10:00:00.000Z',
      'closedAt': null,
      'status': 'OPEN',
      'canApply': true,
    });
    final closed = ApplicationWindow.fromJson({
      'type': 'PRATIBHA_SAMMAN',
      'startsAt': '2026-09-01T10:00:00.000Z',
      'closedAt': '2026-09-29T10:00:00.000Z',
      'status': 'CLOSED',
      'canApply': false,
    });

    await pumpApp(
      tester,
      home: const AdminApplicationsPage(),
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedAdminController()),
        applicationWindowsProvider.overrideWith(
          (ref) async => [scheduled, open, closed],
        ),
      ],
    );

    expect(find.byKey(const ValueKey('application_window_management')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('application_window_start_EDUCATION_ASSISTANCE')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('application_window_start_MEDICAL_HELP')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('application_window_start_PRATIBHA_SAMMAN')),
      findsOneWidget,
    );

    final closedButton = find.byKey(
      const ValueKey('application_window_close_PRATIBHA_SAMMAN'),
    );
    expect(closedButton, findsNothing);

    final openCloseButton = find.byKey(
      const ValueKey('application_window_close_MEDICAL_HELP'),
    );
    await tester.scrollUntilVisible(
      openCloseButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(openCloseButton, findsOneWidget);
  });

  testWidgets('public home exposes login from the shared settings menu', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp(splashDuration: Duration.zero)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app_settings_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('authenticated user can see all application choices', (tester) async {
    await pumpApp(
      tester,
      home: const ApplicationsPage(),
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedAdminController()),
        applicationWindowsProvider.overrideWith((ref) async => [
          ApplicationWindow.fromJson({
            'type': 'EDUCATION_ASSISTANCE',
            'startsAt': '2026-09-01T10:00:00.000Z',
            'closedAt': null,
            'status': 'OPEN',
            'canApply': true,
          }),
          ApplicationWindow.fromJson({
            'type': 'MEDICAL_HELP',
            'startsAt': '2026-09-01T10:00:00.000Z',
            'closedAt': null,
            'status': 'OPEN',
            'canApply': true,
          }),
          ApplicationWindow.fromJson({
            'type': 'PRATIBHA_SAMMAN',
            'startsAt': '2026-09-01T10:00:00.000Z',
            'closedAt': null,
            'status': 'OPEN',
            'canApply': true,
          }),
        ]),
        myHelpApplicationsProvider.overrideWith((ref) async => const []),
      ],
    );

    expect(find.byKey(const ValueKey('application_education')), findsOneWidget);
    expect(find.byKey(const ValueKey('application_medical')), findsOneWidget);
    expect(find.byKey(const ValueKey('application_pratibha')), findsOneWidget);
  });

  testWidgets('authenticated user sees an empty state when application history has no data', (tester) async {
    await pumpApp(
      tester,
      home: const ApplicationsPage(),
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedAdminController()),
        myHelpApplicationsProvider.overrideWith((ref) async => const []),
      ],
    );

    expect(find.byKey(const ValueKey('application_history_empty')), findsOneWidget);
    expect(find.text('You have not submitted any applications yet.'), findsOneWidget);
    expect(find.text('Unable to load applications.'), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('home clearly exposes the help and recognition entry point', (tester) async {
    await pumpApp(tester);

    final applicationsEntry = find.byKey(const ValueKey('home_applications'));
    expect(applicationsEntry, findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
  });

  testWidgets('admin beneficiary card exposes delete action', (tester) async {
    const beneficiary = AdminBeneficiary(
      id: 'beneficiary-1',
      name: 'Rahul Kumar',
      supportedYear: 2025,
      contributionAmount: 25000,
      causeId: 'cause-1',
      isActive: true,
      displayOrder: 1,
    );

    await pumpApp(
      tester,
      home: const AdminBeneficiariesPage(),
      overrides: [
        adminBeneficiariesProvider.overrideWith((ref) async => [beneficiary]),
      ],
    );

    expect(
      find.byKey(const ValueKey('admin_beneficiary_delete_beneficiary-1')),
      findsOneWidget,
    );
  });

  testWidgets('authenticated admin can access admin portal from the reference menu', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedAdminController()),
      ],
    );

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app_settings_menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app_settings_admin_portal')), findsOneWidget);
    expect(find.text(l10n(tester).adminPortal), findsOneWidget);
    expect(find.text(l10n(tester).profile), findsWidgets);
  });

  testWidgets('shared page scaffold keeps the five-tab navigation on detail pages', (tester) async {
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en')).overrideWith(
          (ref) async => _cause,
        ),
      ],
    );

    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Applications'), findsOneWidget);
    expect(find.text('Impact'), findsOneWidget);
    expect(find.text('Information'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    
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

    await tapVisible(tester, find.byKey(const ValueKey('admin_manage_beneficiaries')));
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
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp(splashDuration: Duration.zero)));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('impact navigation opens the real impact explorer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp(splashDuration: Duration.zero)));
    await tester.pumpAndSettle();
    final navigation = AppShellScope.of(tester.element(find.byType(HomePage))).navigation;
    navigation.select(2);
    await tester.pumpAndSettle();
    expect(find.text('Search by name'), findsOneWidget);
  });

  testWidgets('reference home shell keeps a single app bar and five-tab navigation', (tester) async {
    await pumpApp(tester, home: const HomePage());

    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Applications'), findsOneWidget);
    expect(find.text('Impact'), findsOneWidget);
    expect(find.text('Information'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('bottom navigation keeps five labels on one line and evenly aligned', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light(),
        home: Scaffold(
          bottomNavigationBar: AppNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labels = [
      find.text('Home'),
      find.text('Applications'),
      find.text('Impact'),
      find.text('Information'),
      find.text('Profile'),
    ];
    final expectedCenters = [36.0, 108.0, 180.0, 252.0, 324.0];

    for (var i = 0; i < labels.length; i++) {
      expect(labels[i], findsOneWidget);
      expect(tester.getSize(labels[i]).height, lessThanOrEqualTo(24));
      expect(
        tester.getCenter(labels[i]).dx,
        closeTo(expectedCenters[i], 8),
      );
    }
  });

  testWidgets('Applications tab has one shell header and one navigation bar', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedAdminController()),
        applicationWindowsProvider.overrideWith((ref) async => const []),
        myHelpApplicationsProvider.overrideWith((ref) async => const []),
      ],
    );

    final navigation = AppShellScope.of(
      tester.element(find.byType(HomePage)),
    ).navigation;
    navigation.select(1);
    await tester.pumpAndSettle();

    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(find.byType(ApplicationsPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ApplicationsPage),
        matching: anyAppBar,
      ),
      findsNothing,
      reason: 'HomePage must own the shell for tab content.',
    );
  });

  testWidgets('Profile tab has one shell header and one navigation bar', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedAdminController()),
      ],
    );

    final navigation = AppShellScope.of(
      tester.element(find.byType(HomePage)),
    ).navigation;
    navigation.select(4);
    await tester.pumpAndSettle();

    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProfilePage),
        matching: anyAppBar,
      ),
      findsNothing,
      reason: 'HomePage must own the shell for tab content.',
    );
  });

  testWidgets('application history backend failure stays inside the shared shell', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedAdminController()),
        applicationWindowsProvider.overrideWith((ref) async => const []),
        myHelpApplicationsProvider.overrideWith(
          (ref) async => throw Exception('simulated backend unavailable'),
        ),
      ],
    );

    final navigation = AppShellScope.of(
      tester.element(find.byType(HomePage)),
    ).navigation;
    navigation.select(1);
    await tester.pumpAndSettle();

    expect(find.text(l10n(tester).applicationLoadError), findsOneWidget);
    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(find.text('Unable to load'), findsNothing);
  });

  testWidgets('causes backend failure renders a recoverable screen, not a blank or black screen', (tester) async {
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith(
          (ref) async => throw Exception('simulated backend unavailable'),
        ),
      ],
    );

    expect(find.text(l10n(tester).causesLoadError), findsOneWidget);
    expect(find.text(l10n(tester).retry), findsOneWidget);
    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(
      tester.widget<Scaffold>(anyScaffold.first).backgroundColor,
      AppTheme.background,
    );
  });

  testWidgets('causes retry recovers after a transient backend failure', (tester) async {
    var failed = true;
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async {
          if (failed) {
            failed = false;
            throw Exception('transient backend failure');
          }
          return const [_cause];
        }),
      ],
    );

    expect(find.text(l10n(tester).causesLoadError), findsOneWidget);
    await tester.tap(find.text(l10n(tester).retry));
    await tester.pumpAndSettle();

    expect(find.text('Education'), findsOneWidget);
    expect(find.text(l10n(tester).causesLoadError), findsNothing);
    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
  });

  testWidgets('Impact backend failure stays inside the Home shell', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        beneficiariesProvider((search: '', sort: null)).overrideWith(
          (ref) async => throw Exception('simulated backend unavailable'),
        ),
      ],
    );

    final navigation = AppShellScope.of(
      tester.element(find.byType(HomePage)),
    ).navigation;
    navigation.select(2);
    await tester.pumpAndSettle();

    expect(find.text(l10n(tester).impactLoadError), findsOneWidget);
    expect(find.text(l10n(tester).tryAgain), findsOneWidget);
    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
  });

  testWidgets('opening Causes from Home keeps the route on the application shell', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
      ],
    );

    await tester.tap(find.text('Service'));
    await tester.pumpAndSettle();

    expect(find.byType(CausesPage), findsOneWidget);
    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(anyScaffold.last).backgroundColor,
      AppTheme.background,
    );
  });

  testWidgets('causes success screen keeps the application background and shell', (tester) async {
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
      ],
    );

    expect(find.text('Education'), findsOneWidget);
    expect(anyAppBar, findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
    expect(
      tester.widget<Scaffold>(anyScaffold.first).backgroundColor,
      AppTheme.background,
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

    expect(anyAppBar, findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomePage),
        matching: anyAppBar,
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ImpactPage),
        matching: anyAppBar,
      ),
      findsNothing,
      reason: 'ImpactPage must remain body-only; HomePage owns the single app bar.',
    );
  });

  testWidgets('Impact sort options use the active locale instead of English-only labels', (tester) async {
    await pumpApp(
      tester,
      home: const HomePage(),
      overrides: [
        beneficiariesProvider((search: '', sort: null))
            .overrideWith((ref) async => const <Beneficiary>[]),
      ],
    );

    final navigation = AppShellScope.of(
      tester.element(find.byType(HomePage)),
    ).navigation;
    navigation.select(2);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('beneficiary_sort')));
    await tester.pumpAndSettle();

    expect(find.text(l10n(tester).impactSortNewest), findsWidgets);
    expect(find.text(l10n(tester).impactSortName), findsOneWidget);
    expect(find.text(l10n(tester).impactSortHighest), findsOneWidget);
    expect(find.text(l10n(tester).impactSortLowest), findsOneWidget);
  });

  testWidgets('language selector opens and shows all supported languages', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp(splashDuration: Duration.zero)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app_settings_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language').last);
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Marathi'), findsOneWidget);
    expect(find.text('Gujarati'), findsOneWidget);
  });

  testWidgets('language selector changes the app locale', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp(splashDuration: Duration.zero)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app_settings_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hindi'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('selected_locale'), 'hi');
  });

  testWidgets('causes page exposes both education assistance and Pratibha Samman categories', (tester) async {
    const causes = [
      Cause(id: 'education-assistance', slug: 'education-assistance', name: 'Education Assistance'),
      Cause(id: 'pratibha-samman', slug: 'pratibha-samman', name: 'Pratibha Samman'),
    ];
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => causes),
      ],
    );

    expect(find.text('Education Assistance'), findsOneWidget);
    expect(find.text('Pratibha Samman'), findsOneWidget);
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
    expect(find.byIcon(Icons.subdirectory_arrow_right_rounded), findsOneWidget);
  });

  testWidgets('cause details show a localized retry state when loading fails', (tester) async {
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en')).overrideWith(
          (ref) async => throw Exception('simulated API failure'),
        ),
      ],
    );

    expect(find.text('Unable to load this cause.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
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
    final organisation = find.text('Seva Trust');
    await tester.scrollUntilVisible(
      organisation,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(organisation, findsOneWidget);
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

    final organisation = find.text('Seva Trust');
    await tester.scrollUntilVisible(
      organisation,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(organisation, findsOneWidget);
    expect(find.text('Pune, Maharashtra'), findsOneWidget);
    expect(find.text('Support this Cause'), findsOneWidget);
  });

  testWidgets('education cause detail describes assistance and recognition and offers education assistance application', (tester) async {
    const education = Cause(
      id: 'education',
      slug: 'education',
      name: 'Education',
      description: 'We support students from financially underserved backgrounds so they can continue their education, and celebrate talented individuals whose achievements inspire others through Pratibha Samman.',
    );
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => education),
      ],
    );

    expect(find.textContaining('financially underserved backgrounds'), findsOneWidget);
    expect(find.textContaining('Pratibha Samman'), findsOneWidget);
    expect(find.byKey(const ValueKey('cause_apply_EDUCATION_ASSISTANCE')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cause_apply_EDUCATION_ASSISTANCE')));
    await tester.pumpAndSettle();
    expect(find.byType(HelpApplicationFormPage), findsOneWidget);
  });

  testWidgets('healthcare cause detail offers medical help application', (tester) async {
    const healthcare = Cause(
      id: 'healthcare',
      slug: 'healthcare',
      name: 'Healthcare',
      description: 'Support for healthcare and medical assistance.',
    );
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'healthcare'),
      overrides: [
        causeProvider((slug: 'healthcare', languageCode: 'en'))
            .overrideWith((ref) async => healthcare),
      ],
    );

    final applyButton = find.byKey(const ValueKey('cause_apply_MEDICAL_HELP'));
    expect(applyButton, findsOneWidget);
    expect(find.text('Apply for Medical Help'), findsOneWidget);

    await tester.tap(applyButton);
    await tester.pumpAndSettle();
    expect(find.byType(HelpApplicationFormPage), findsOneWidget);
  });

  Future<void> expectCauseApplicationCta(
    WidgetTester tester, {
    required String slug,
    required Cause cause,
    required String applicationType,
    required String label,
  }) async {
    await pumpApp(
      tester,
      home: CauseDetailPage(slug: slug),
      overrides: [
        causeProvider((slug: slug, languageCode: 'en'))
            .overrideWith((ref) async => cause),
      ],
    );

    final applyButton = find.byKey(ValueKey('cause_apply_$applicationType'));
    expect(
      applyButton,
      findsOneWidget,
      reason: '$slug must expose its application CTA',
    );

    final button = tester.widget<OutlinedButton>(applyButton);
    expect(
      button.style?.foregroundColor?.resolve({}),
      const Color(0xFFF5A623),
    );
    expect(
      button.style?.side?.resolve({}),
      const BorderSide(color: Color(0xFFF5A623)),
    );
    expect(find.text(label), findsOneWidget);

    await tester.tap(applyButton);
    await tester.pumpAndSettle();
    expect(find.byType(HelpApplicationFormPage), findsOneWidget);
  }

  testWidgets('education assistance cause detail exposes a consistent application CTA', (tester) async {
    await expectCauseApplicationCta(
      tester,
      slug: 'education-assistance',
      cause: const Cause(
        id: 'education-assistance',
        slug: 'education-assistance',
        name: 'Education Assistance',
        description: 'Need-based support for students.',
      ),
      applicationType: 'EDUCATION_ASSISTANCE',
      label: 'Apply for Education Assistance',
    );
  });

  testWidgets('healthcare cause detail exposes a consistent application CTA', (tester) async {
    await expectCauseApplicationCta(
      tester,
      slug: 'healthcare',
      cause: const Cause(
        id: 'healthcare',
        slug: 'healthcare',
        name: 'Healthcare',
        description: 'Support for healthcare and medical assistance.',
      ),
      applicationType: 'MEDICAL_HELP',
      label: 'Apply for Medical Help',
    );
  });

  testWidgets('Pratibha Samman cause detail exposes a consistent application CTA', (tester) async {
    await expectCauseApplicationCta(
      tester,
      slug: 'pratibha-samman',
      cause: const Cause(
        id: 'pratibha-samman',
        slug: 'pratibha-samman',
        name: 'Pratibha Samman',
        description: 'Recognize and honour exceptional achievements.',
      ),
      applicationType: 'PRATIBHA_SAMMAN',
      label: 'Apply for Pratibha Samman',
    );
  });

  testWidgets('support cause button opens donation page', (tester) async {
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => _cause),
        causesProvider('en').overrideWith((ref) async => const [_cause]),
      ],
    );

    await tapVisible(tester, find.text('Support this Cause'));
    await tester.pumpAndSettle();

    expect(find.byType(DonationPage), findsOneWidget);
    expect(find.text(l10n(tester).chooseAmount), findsOneWidget);

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    expect(amountField, findsOneWidget);
  });

  testWidgets('contribution page keeps shared settings and bottom navigation visible', (tester) async {
    await pumpDonationPage(tester);

    expect(find.byKey(const ValueKey('app_settings_menu')), findsOneWidget);
    expect(find.byType(AppNavigationBar), findsOneWidget);
  });

  testWidgets('donation defaults a single selected cause to 100 percent', (tester) async {
    await pumpDonationPage(tester);
    expect(
      find.byKey(const ValueKey('donation_percentage_cause-1')),
      findsNothing,
      reason: 'The percentage input is intentionally lazy-built below the fold.',
    );
    final amountField = tester.widget<TextField>(
      find.byKey(const ValueKey('donation_amount_input')),
    );
    expect(amountField.controller?.text, isEmpty);
  });

  testWidgets('selecting a second cause defaults allocation equally', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
    ];
    await pumpDonationPage(tester, causes: causes);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('donation_cause_cause-2')),
    );

    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-1')),
      ).controller?.text,
      '50',
    );
    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-2')),
      ).controller?.text,
      '50',
    );
    expect(find.text('Total allocation: 100%'), findsOneWidget);
  });

  testWidgets('allocation percentage fields stay synchronized when causes change', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
      Cause(id: 'cause-3', slug: 'medical', name: 'Medical'),
    ];
    await pumpDonationPage(tester, causes: causes);

    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_amount_input')),
      '2000',
    );
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-3')));

    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-1')),
      ).controller?.text,
      '34',
    );
    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-2')),
      ).controller?.text,
      '33',
    );
    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-3')),
      ).controller?.text,
      '33',
    );

    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-3')));

    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-1')),
      ).controller?.text,
      '50',
    );
    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-2')),
      ).controller?.text,
      '50',
    );
    expect(find.text('₹ 1000.00'), findsNWidgets(2));
    expect(find.text('Total allocation: 100%'), findsOneWidget);
  });

  testWidgets('three selected causes default to a complete 100 percent split', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
      Cause(id: 'cause-3', slug: 'medical', name: 'Medical'),
    ];
    await pumpDonationPage(tester, causes: causes);

    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-3')));

    expect(find.text('Total allocation: 100%'), findsOneWidget);
  });

  testWidgets('donation attempt shows feature is not enabled message', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
    ];
    await pumpDonationPage(tester, causes: causes);

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_percentage_cause-1')),
      '70',
    );
    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_percentage_cause-2')),
      '30',
    );

    await tapVisible(tester, find.byKey(const ValueKey('donation_submit')));

    expect(
      find.text(l10n(tester).donationNotEnabledYet),
      findsOneWidget,
    );
  });

  testWidgets('donation submit is disabled when allocation does not total 100 percent', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
    ];
    await pumpDonationPage(tester, causes: causes);

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_percentage_cause-1')),
      '70',
    );
    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_percentage_cause-2')),
      '20',
    );

    final submitFinder = find.byKey(const ValueKey('donation_submit'));
    await tester.ensureVisible(submitFinder);
    await tester.pump();
    final submit = tester.widget<FilledButton>(submitFinder);
    expect(submit.onPressed, isNull);
    expect(find.text('Total allocation: 90%'), findsOneWidget);
  });

  testWidgets('preset amount updates donation amount field', (tester) async {
    await pumpDonationPage(tester);

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_500')));

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('donation_amount_input')),
          )
          .controller
          ?.text,
      '500',
    );
  });
}

class _AuthenticatedAdminController extends AuthController {
  _AuthenticatedAdminController()
      : super(_NoopAuthRepository()) {
    state = const AuthState.authenticated(
      AppUser(
        id: 'admin-1',
        email: 'admin@example.com',
        displayName: 'Admin',
        role: UserRole.admin,
      ),
    );
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AppUser?> restoreSession() async => const AppUser(
        id: 'admin-1',
        email: 'admin@example.com',
        displayName: 'Admin',
        role: UserRole.admin,
      );

  @override
  Future<void> signOut() async {}
}
