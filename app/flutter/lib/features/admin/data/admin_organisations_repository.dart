import '../../../core/network/api_client.dart';
import '../models/admin_organisation.dart';

class AdminOrganisationsRepository {
  AdminOrganisationsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<AdminOrganisation>> getOrganisations() async {
    return (await _apiClient.getAdminOrganisations())
        .map(AdminOrganisation.fromJson)
        .toList(growable: false);
  }

  Future<AdminOrganisation> create(Map<String, dynamic> payload) async {
    return AdminOrganisation.fromJson(
      await _apiClient.createAdminOrganisation(payload),
    );
  }

  Future<AdminOrganisation> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    return AdminOrganisation.fromJson(
      await _apiClient.updateAdminOrganisation(id, payload),
    );
  }

  Future<void> setActive(String id, bool active) async {
    await _apiClient.setAdminOrganisationActive(id, active);
  }

  Future<void> updateCauses(String id, List<String> causeIds) async {
    await _apiClient.updateAdminOrganisationCauses(id, causeIds);
  }
}
