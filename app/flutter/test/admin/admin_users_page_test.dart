import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/admin/data/admin_users_repository.dart';
import 'package:avijit_sahyog/features/admin/models/admin_user.dart';
import 'package:avijit_sahyog/features/admin/models/paginated_admin_users.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_users_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_users_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

AdminUser _user(String id, String name, {String role = 'ADMIN'}) => AdminUser(
      id: id,
      displayName: name,
      email: '$id@example.com',
      photoUrl: null,
      role: role,
      createdAt: DateTime.utc(2026, 9, 14),
    );

class _FakeAdminUsersRepository extends AdminUsersRepository {
  _FakeAdminUsersRepository({this.failRoleChange = false}) : super(ApiClient());

  bool failRoleChange;
  final Map<String, AdminUser> users = {
    'nikita-user': _user('nikita-user', 'Nikita Manoriya', role: 'USER'),
    'nikita-admin': _user('nikita-admin', 'Nikita Sharma', role: 'ADMIN'),
  };
  final List<(String userId, String role)> roleChanges = [];

  @override
  Future<PaginatedAdminUsers> getUsers({
    String? search,
    String role = 'ADMIN',
    int page = 1,
    int pageSize = 3,
  }) async {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final matching = users.values
        .where((user) =>
            (role == 'ALL' || user.role == role) &&
            (normalizedSearch.isEmpty ||
                user.label.toLowerCase().contains(normalizedSearch) ||
                (user.email?.toLowerCase().contains(normalizedSearch) ?? false)))
        .toList(growable: false);
    final start = (page - 1) * pageSize;
    final items = start >= matching.length
        ? const <AdminUser>[]
        : matching.skip(start).take(pageSize).toList(growable: false);
    return PaginatedAdminUsers(
      items: items,
      page: page,
      pageSize: pageSize,
      total: matching.length,
    );
  }

  @override
  Future<AdminUser> changeRole(String userId, String role) async {
    roleChanges.add((userId, role));
    if (failRoleChange) {
      throw Exception('role change failed');
    }
    final user = users[userId]!;
    final updated = _user(user.id, user.label, role: role);
    users[userId] = updated;
    return updated;
  }
}

Widget _buildPage(_FakeAdminUsersRepository repository) {
  return ProviderScope(
    overrides: [
      adminUsersRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const AdminUsersPage(),
    ),
  );
}

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

  testWidgets('shows a genuine no-results state when no user matches the search', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUsersProvider.overrideWith((ref, query) async => PaginatedAdminUsers(
                items: const [],
                page: query.page,
                pageSize: 3,
                total: 0,
              )),
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
    await tester.enterText(find.byType(TextField).first, 'does-not-exist');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No users found.'), findsOneWidget);
    expect(find.text('Make admin'), findsNothing);
  });

  testWidgets('search shows multiple matching users with details and allows selecting the correct user', (tester) async {
    final repository = _FakeAdminUsersRepository();
    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'nikita');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('2 matching users'), findsOneWidget);
    expect(find.text('Nikita Manoriya'), findsOneWidget);
    expect(find.text('Nikita Sharma'), findsOneWidget);
    expect(find.text('nikita-user@example.com'), findsOneWidget);
    expect(find.text('nikita-admin@example.com'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Make admin'), findsNWidgets(3));

    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Make admin'), findsOneWidget);
    await tester.tap(find.text('Make admin').last);
    await tester.pumpAndSettle();

    expect(repository.roleChanges, [('nikita-user', 'ADMIN')]);
    expect(repository.users['nikita-user']!.role, 'ADMIN');
    expect(find.text('User is now an administrator and the change was recorded.'), findsOneWidget);
  });

  testWidgets('cancelling promotion leaves the user unchanged', (tester) async {
    final repository = _FakeAdminUsersRepository();
    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_add_alt_1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nikita Manoriya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.roleChanges, isEmpty);
    expect(repository.users['nikita-user']!.role, 'USER');
  });

  testWidgets('promotion failure keeps the user as a normal user and shows the error', (tester) async {
    final repository = _FakeAdminUsersRepository(failRoleChange: true);
    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_add_alt_1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nikita Manoriya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make admin').last);
    await tester.pumpAndSettle();

    expect(repository.users['nikita-user']!.role, 'USER');
    expect(repository.roleChanges, [('nikita-user', 'ADMIN')]);
    expect(find.textContaining('role change failed'), findsOneWidget);
  });

  testWidgets('cancelling demotion keeps the administrator unchanged', (tester) async {
    final repository = _FakeAdminUsersRepository();
    repository.users['nikita-user'] = _user('nikita-user', 'Nikita Manoriya');
    repository.users.remove('nikita-admin');
    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.roleChanges, isEmpty);
    expect(repository.users['nikita-user']!.role, 'ADMIN');
    expect(find.text('Nikita Manoriya'), findsOneWidget);
  });

  testWidgets('successful demotion removes the administrator from the refreshed list', (tester) async {
    final repository = _FakeAdminUsersRepository();
    repository.users['nikita-user'] = _user('nikita-user', 'Nikita Manoriya');
    repository.users.remove('nikita-admin');
    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove admin').last);
    await tester.pumpAndSettle();

    expect(repository.roleChanges, [('nikita-user', 'USER')]);
    expect(repository.users['nikita-user']!.role, 'USER');
    expect(find.text('Nikita Manoriya'), findsNothing);
  });

  testWidgets('demotion failure keeps the administrator visible', (tester) async {
    final repository = _FakeAdminUsersRepository(failRoleChange: true);
    repository.users['nikita-user'] = _user('nikita-user', 'Nikita Manoriya');
    repository.users.remove('nikita-admin');
    await tester.pumpWidget(_buildPage(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove admin').last);
    await tester.pumpAndSettle();

    expect(repository.users['nikita-user']!.role, 'ADMIN');
    expect(repository.roleChanges, [('nikita-user', 'USER')]);
    expect(find.text('Nikita Manoriya'), findsOneWidget);
    expect(find.textContaining('role change failed'), findsOneWidget);
  });
}
