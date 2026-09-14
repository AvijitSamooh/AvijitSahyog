import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/features/admin/models/admin_user.dart';
import 'package:avijit_sahyog/features/admin/models/paginated_admin_users.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_users_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_users_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

AdminUser _user(String id, String name) => AdminUser(
      id: id,
      displayName: name,
      email: '$id@example.com',
      photoUrl: null,
      role: 'ADMIN',
      createdAt: DateTime.utc(2026, 9, 14),
    );

void main() {
  testWidgets('shows only the current server page of administrators', (tester) async {
    final pageOne = PaginatedAdminUsers(
      items: [_user('one', 'Admin One'), _user('two', 'Admin Two'), _user('three', 'Admin Three')],
      page: 1,
      pageSize: 3,
      total: 4,
    );
    final pageTwo = PaginatedAdminUsers(
      items: [_user('four', 'Admin Four')],
      page: 2,
      pageSize: 3,
      total: 4,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUsersProvider.overrideWith((ref, query) async {
            if (query.page == 2) return pageTwo;
            return pageOne;
          }),
          adminAuditHistoryProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const AdminUsersPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin One'), findsOneWidget);
    expect(find.text('Admin Two'), findsOneWidget);
    expect(find.text('Admin Three'), findsOneWidget);
    expect(find.text('Admin Four'), findsNothing);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();

    expect(find.text('Admin One'), findsNothing);
    expect(find.text('Admin Four'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('search resets pagination and asks the provider for the search term', (tester) async {
    ({String? search, int page})? observed;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUsersProvider.overrideWith((ref, query) async {
            observed = (search: query.search, page: query.page);
            return PaginatedAdminUsers(
              items: query.search == 'nikita' ? [_user('nikita', 'Nikita')] : const [],
              page: query.page,
              pageSize: 3,
              total: query.search == 'nikita' ? 1 : 0,
            );
          }),
          adminAuditHistoryProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const AdminUsersPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'nikita');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(observed, (search: 'nikita', page: 1));
    expect(find.text('Nikita'), findsOneWidget);
  });
}
