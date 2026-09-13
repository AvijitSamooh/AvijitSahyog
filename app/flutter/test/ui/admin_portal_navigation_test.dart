import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_portal_page.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  testWidgets('admin portal keeps the shared bottom navigation visible', (tester) async {
    final navigation = AppNavigationController();

    await tester.pumpWidget(
      AppShellScope(
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
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Causes'), findsOneWidget);
    expect(find.text('Impact'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
