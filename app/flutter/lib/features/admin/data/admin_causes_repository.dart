import '../../../core/network/api_client.dart';
import '../models/admin_cause.dart';

class AdminCausesRepository {
  AdminCausesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AdminCause>> getCauses() async {
    return (await _apiClient.getAdminCauses())
        .map(AdminCause.fromJson)
        .toList(growable: false);
  }

  Future<AdminCause> createCause(Map<String, dynamic> payload) async {
    return AdminCause.fromJson(await _apiClient.createAdminCause(payload));
  }

  Future<AdminCause> updateCause(
    String id,
    Map<String, dynamic> payload,
  ) async {
    return AdminCause.fromJson(
      await _apiClient.updateAdminCause(id, payload),
    );
  }

  Future<AdminCause> setActive(String id, bool isActive) async {
    return AdminCause.fromJson(
      await _apiClient.setAdminCauseActive(id, isActive),
    );
  }
}
