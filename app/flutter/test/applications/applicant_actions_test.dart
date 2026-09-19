import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/applications/data/help_applications_repository.dart';
import 'package:avijit_sahyog/features/applications/models/help_application.dart';
import 'package:avijit_sahyog/features/applications/presentation/applications_page.dart';
import 'package:avijit_sahyog/features/applications/providers/help_applications_providers.dart';
import 'package:avijit_sahyog/features/auth/data/auth_repository.dart';
import 'package:avijit_sahyog/features/auth/models/app_user.dart';
import 'package:avijit_sahyog/features/auth/models/auth_state.dart';
import 'package:avijit_sahyog/features/auth/providers/auth_providers.dart';
import 'package:avijit_sahyog/features/causes/models/cause.dart';
import 'package:avijit_sahyog/features/causes/models/organisation.dart';
import 'package:avijit_sahyog/features/causes/presentation/cause_detail_page.dart';
import 'package:avijit_sahyog/features/causes/providers/causes_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

class _FakeHelpApplicationsRepository extends HelpApplicationsRepository {
  _FakeHelpApplicationsRepository(this.items) : super(ApiClient());
  List<HelpApplication> items;
  int deleteCalls = 0;
  @override
  Future<void> delete(String id) async {
    deleteCalls++;
    items = items.where((item) => item.id != id).toList(growable: false);
  }
}

class _AuthenticatedController extends AuthController {
  _AuthenticatedController() : super(_NoopAuthRepository()) {
    state = const AuthState.authenticated(
      AppUser(id: 'user-1', email: 'user@example.com', displayName: 'User', role: UserRole.user),
    );
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<AppUser> signInWithGoogle() => throw UnimplementedError();
  @override
  Future<AppUser?> restoreSession() async => const AppUser(
        id: 'user-1', email: 'user@example.com', displayName: 'User', role: UserRole.user);
  @override
  Future<void> signOut() async {}
}

Future<void> _pump(WidgetTester tester, {required Widget home, List<Override> overrides = const []}) async {
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
          home: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('applicant can delete a non-final application', (tester) async {
    final repository = _FakeHelpApplicationsRepository([
      const HelpApplication(
        id: 'app-1',
        type: 'MEDICAL_HELP',
        status: 'SUBMITTED',
        applicantName: 'User',
        mobileNumber: '9876543210',
      ),
    ]);
    await _pump(tester, home: const ApplicationsPage(), overrides: [
      authProvider.overrideWith((ref) => _AuthenticatedController()),
      helpApplicationsRepositoryProvider.overrideWithValue(repository),
      myHelpApplicationsProvider.overrideWith((ref) async => repository.items),
    ]);
    await tester.tap(find.byKey(const ValueKey('application_delete_app-1')));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to delete this application? This cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Delete application'));
    await tester.pumpAndSettle();
    expect(repository.deleteCalls, 1);
    expect(find.text('Application deleted.'), findsOneWidget);
  });

  testWidgets('cause detail shows phone and WhatsApp actions when only phone is supplied', (tester) async {
    const organisation = Organisation(
      id: 'org-1',
      slug: 'seva',
      name: 'Seva Trust',
      phone: '9876543210',
      city: 'Pune',
      state: 'Maharashtra',
    );
    const cause = Cause(
      id: 'cause-1',
      slug: 'jeev-daya',
      name: 'Jeev Daya',
      organisations: [organisation],
    );
    await _pump(
      tester,
      home: const CauseDetailPage(slug: 'jeev-daya'),
      overrides: [
        causeProvider((slug: 'jeev-daya', languageCode: 'en'))
            .overrideWith((ref) async => cause),
      ],
    );
    expect(find.byKey(const ValueKey('affiliate_call_org-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('affiliate_whatsapp_org-1')), findsOneWidget);
  });
}
