import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/features/admin/models/admin_user.dart';
import 'package:avijit_sahyog/features/admin/models/paginated_admin_users.dart';

void main() {
  test('calculates pagination metadata for three-item pages', () {
    final result = PaginatedAdminUsers(
      items: const [],
      page: 2,
      pageSize: 3,
      total: 7,
    );

    expect(result.totalPages, 3);
    expect(result.hasPreviousPage, isTrue);
    expect(result.hasNextPage, isTrue);
  });

  test('last page has no next page', () {
    final result = PaginatedAdminUsers(
      items: const [],
      page: 3,
      pageSize: 3,
      total: 7,
    );

    expect(result.hasPreviousPage, isTrue);
    expect(result.hasNextPage, isFalse);
  });

  test('admin user JSON retains role and profile data', () {
    final user = AdminUser.fromJson({
      'id': 'admin-1',
      'email': 'admin@example.com',
      'displayName': 'Admin',
      'photoUrl': null,
      'role': 'ADMIN',
      'createdAt': '2026-09-14T00:00:00.000Z',
    });

    expect(user.isAdmin, isTrue);
    expect(user.canBeDemoted, isTrue);
    expect(user.canBePromoted, isFalse);
    expect(user.label, 'Admin');
  });
}
