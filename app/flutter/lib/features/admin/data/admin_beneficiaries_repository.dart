import '../../../core/network/api_client.dart';
import '../models/admin_beneficiary.dart';

class AdminBeneficiariesRepository {
  AdminBeneficiariesRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<AdminBeneficiary>> getBeneficiaries() async {
    return (await _apiClient.getAdminBeneficiaries())
        .map(AdminBeneficiary.fromJson)
        .toList(growable: false);
  }

  Future<AdminBeneficiary> create(Map<String, dynamic> payload) async {
    return AdminBeneficiary.fromJson(
      await _apiClient.createAdminBeneficiary(payload),
    );
  }

  Future<AdminBeneficiary> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    return AdminBeneficiary.fromJson(
      await _apiClient.updateAdminBeneficiary(id, payload),
    );
  }

  Future<void> setActive(String id, bool active) =>
      _apiClient.setAdminBeneficiaryActive(id, active);
}
