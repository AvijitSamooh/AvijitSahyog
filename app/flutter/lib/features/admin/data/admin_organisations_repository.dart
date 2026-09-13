import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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

  Future<void> delete(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await http.delete(
      Uri.parse('${_apiClient.baseUrl}/admin/organisations/$id'),
      headers: headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = response.body.trim();
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message'];
          detail = message is List ? message.join(', ') : (message?.toString() ?? detail);
        }
      } catch (_) {
        // Keep the raw response when it is not JSON.
      }
      throw Exception(
        'Deleting organisation failed: ${response.statusCode}${detail.isEmpty ? '' : ': $detail'}',
      );
    }
  }
}
