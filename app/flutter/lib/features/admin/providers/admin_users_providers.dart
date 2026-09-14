import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_users_repository.dart';
import '../models/admin_audit_entry.dart';
import '../models/paginated_admin_users.dart';
import 'admin_causes_providers.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(ref.watch(adminApiClientProvider));
});

final adminUsersProvider = FutureProvider.autoDispose.family<PaginatedAdminUsers, ({String? search, int page, String role})>((ref, query) {
  return ref.watch(adminUsersRepositoryProvider).getUsers(
        search: query.search,
        role: query.role,
        page: query.page,
        pageSize: 3,
      );
});

final adminAuditHistoryProvider = FutureProvider.autoDispose<List<AdminAuditEntry>>((ref) {
  return ref.watch(adminUsersRepositoryProvider).getAuditHistory();
});
