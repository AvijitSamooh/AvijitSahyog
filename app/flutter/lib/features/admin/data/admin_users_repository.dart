import '../../../core/network/api_client.dart';
import '../models/admin_audit_entry.dart';
import '../models/admin_user.dart';
import '../models/paginated_admin_users.dart';

class AdminUsersRepository {
  AdminUsersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedAdminUsers> getUsers({
    String? search,
    String role = 'ADMIN',
    int page = 1,
    int pageSize = 3,
  }) async {
    final json = await _apiClient.getAdminUsers(
      search: search,
      role: role,
      page: page,
      pageSize: pageSize,
    );
    return PaginatedAdminUsers(
      items: (json['items'] as List<dynamic>)
          .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
    );
  }

  Future<AdminUser> changeRole(String userId, String role) async {
    return AdminUser.fromJson(
      await _apiClient.makeAdmin(userId, role: role),
    );
  }

  Future<List<AdminAuditEntry>> getAuditHistory() async {
    return (await _apiClient.getAdminAuditHistory())
        .map(AdminAuditEntry.fromJson)
        .toList(growable: false);
  }
}
