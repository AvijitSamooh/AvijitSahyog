import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_users_repository.dart';
import '../models/admin_audit_entry.dart';
import '../models/admin_user.dart';
import 'admin_causes_providers.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(ref.watch(adminApiClientProvider));
});

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) {
  return ref.watch(adminUsersRepositoryProvider).getUsers();
});

final adminAuditHistoryProvider =
    FutureProvider.autoDispose<List<AdminAuditEntry>>((ref) {
  return ref.watch(adminUsersRepositoryProvider).getAuditHistory();
});
