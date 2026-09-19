import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_portal_page.dart';
import 'package:avijit_sahyog/features/auth/data/auth_repository.dart';
import 'package:avijit_sahyog/features/auth/models/app_user.dart';
import 'package:avijit_sahyog/features/auth/models/auth_state.dart';
import 'package:avijit_sahyog/features/auth/providers/auth_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

class _NavigationAuthController extends AuthController {
  _NavigationAuthController() : super(_NavigationAuthRepository()) {
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

class _NavigationAuthRepository implements AuthRepository {
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

void main() {
  testWidgets('admin portal keeps shared navigation and hides super-admin controls', (tester) async {
    final navigation = AppNavigationController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _NavigationAuthController()),
        ],
        child: AppShellScope(
          onLocaleChanged: (_) {},
          navigation: navigation,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: ThemeData(useMaterial3: true),
            home: const AdminPortalPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Causes'), findsOneWidget);
    expect(find.text('Impact'), findsOneWidget);

    expect(find.text('Interaction analytics'), findsNothing);
    expect(find.text('Advanced analytics'), findsNothing);
    expect(find.text('Platform health'), findsNothing);
    expect(find.text('Manage administrators'), findsNothing);
  });
}
