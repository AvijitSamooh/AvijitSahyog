import '../../../core/network/api_client.dart';
import '../models/admin_audit_entry.dart';
import '../models/admin_user.dart';

class AdminUsersRepository {
  AdminUsersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AdminUser>> getUsers() async {
    return (await _apiClient.getAdminUsers())
        .map(AdminUser.fromJson)
        .toList(growable: false);
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
