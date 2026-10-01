import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/features/applications/models/application_rule.dart';
import 'package:avijit_sahyog/features/applications/models/application_window.dart';
import 'package:avijit_sahyog/features/applications/presentation/applications_page.dart';
import 'package:avijit_sahyog/features/applications/providers/help_applications_providers.dart';
import 'package:avijit_sahyog/features/auth/data/auth_repository.dart';
import 'package:avijit_sahyog/features/auth/models/app_user.dart';
import 'package:avijit_sahyog/features/auth/models/auth_state.dart';
import 'package:avijit_sahyog/features/auth/providers/auth_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AppUser?> restoreSession() async => const AppUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'User',
        role: UserRole.user,
      );

  @override
  Future<void> signOut() async {}
}

class _AnonymousAuthRepository implements AuthRepository {
  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<void> signOut() async {}
}

class _AuthenticatedController extends AuthController {
  _AuthenticatedController() : super(_NoopAuthRepository()) {
    state = const AuthState.authenticated(
      AppUser(id: 'user-1', email: 'user@example.com', displayName: 'User', role: UserRole.user),
    );
  }
}

ApplicationWindow _window({
  required String type,
  required String status,
  required String startsAt,
  String? closedAt,
}) {
  return ApplicationWindow.fromJson({
    'type': type,
    'startsAt': startsAt,
    'closedAt': closedAt,
    'status': status,
    'canApply': status == 'OPEN',
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required List<ApplicationWindow> windows,
  List<ApplicationRule> rules = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _AuthenticatedController()),
        applicationWindowsProvider.overrideWith((ref) async => windows),
        myHelpApplicationsProvider.overrideWith((ref) async => const []),
        applicationRulesProvider(
          (type: 'PRATIBHA_SAMMAN', language: 'en'),
        ).overrideWith((ref) async => rules),
      ],
      child: AppShellScope(
        onLocaleChanged: (_) {},
        navigation: AppNavigationController(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ApplicationsPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('unauthenticated users are directed to sign in before applying', (tester) async {
    final auth = AuthController(_AnonymousAuthRepository());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          applicationWindowsProvider.overrideWith((ref) async => [
            _window(
              type: 'PRATIBHA_SAMMAN',
              status: 'OPEN',
              startsAt: '2026-09-01T10:00:00.000Z',
            ),
          ]),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ApplicationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to apply'), findsOneWidget);
  });

  testWidgets('applicant sees scheduled, open and closed states and can enter an open application', (tester) async {
    await _pump(
      tester,
      windows: [
        _window(
          type: 'EDUCATION_ASSISTANCE',
          status: 'SCHEDULED',
          startsAt: '2026-10-05T10:00:00.000Z',
        ),
        _window(
          type: 'PRATIBHA_SAMMAN',
          status: 'OPEN',
          startsAt: '2026-09-01T10:00:00.000Z',
        ),
        _window(
          type: 'MEDICAL_HELP',
          status: 'CLOSED',
          startsAt: '2026-09-01T10:00:00.000Z',
          closedAt: '2026-09-30T10:00:00.000Z',
        ),
      ],
    );

    expect(find.textContaining('Applications will start from'), findsOneWidget);
    expect(find.text('Applications are no longer being accepted.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('application_pratibha')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('application_submit')), findsOneWidget);
  });

  testWidgets('application form presents every active rule before submission', (tester) async {
    await _pump(
      tester,
      windows: [
        _window(
          type: 'PRATIBHA_SAMMAN',
          status: 'OPEN',
          startsAt: '2026-09-01T10:00:00.000Z',
        ),
      ],
      rules: const [
        ApplicationRule(
          id: 'rule-1',
          type: 'PRATIBHA_SAMMAN',
          displayOrder: 1,
          text: 'Candidate must be from Pune.',
        ),
        ApplicationRule(
          id: 'rule-2',
          type: 'PRATIBHA_SAMMAN',
          displayOrder: 2,
          text: 'Minimum marks must be 80%.',
        ),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('application_pratibha')));
    await tester.pumpAndSettle();

    expect(find.text('Application rules'), findsOneWidget);
    expect(find.text('1. Candidate must be from Pune.'), findsOneWidget);
    expect(find.text('2. Minimum marks must be 80%.'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
  });
}
