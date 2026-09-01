import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = _normalizeBaseUrl(
          baseUrl ?? const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:3000',
          ),
        );

  static String _normalizeBaseUrl(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  final http.Client _client;
  final String baseUrl;

  Future<Map<String, dynamic>> getHealth() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/health'),
    );

    _ensureSuccess(response, 'Health check');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCauses(String languageCode) async {
    final uri = Uri.parse('$baseUrl/causes').replace(
      queryParameters: {'language': languageCode},
    );

    final response = await _client.get(uri);
    _ensureSuccess(response, 'Loading causes');

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => item as Map<String, dynamic>)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getCause(
    String slug,
    String languageCode,
  ) async {
    final uri = Uri.parse('$baseUrl/causes/$slug').replace(
      queryParameters: {'language': languageCode},
    );

    final response = await _client.get(uri);
    _ensureSuccess(response, 'Loading cause');

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getBeneficiaries({String? search, String? sort}) async {
    final uri = Uri.parse('$baseUrl/beneficiaries').replace(queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    });
    final response = await _client.get(uri);
    _ensureSuccess(response, 'Loading beneficiaries');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((item) => item as Map<String, dynamic>).toList(growable: false);
  }

  Future<Map<String, dynamic>> createDonation(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/donations'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    _ensureSuccess(response, 'Creating donation');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }



  Future<List<Map<String, dynamic>>> getAdminOrganisations() async {
    final response = await _client.get(Uri.parse('$baseUrl/admin/organisations'));
    _ensureSuccess(response, 'Loading admin organisations');
    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAdminOrganisation(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/admin/organisations'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureSuccess(response, 'Creating organisation');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminOrganisation(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/admin/organisations/$id'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureSuccess(response, 'Updating organisation');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> setAdminOrganisationActive(String id, bool active) async {
    final action = active ? 'activate' : 'deactivate';
    final response = await _client.patch(
      Uri.parse('$baseUrl/admin/organisations/$id/$action'),
    );
    _ensureSuccess(response, 'Updating organisation status');
  }

  Future<void> updateAdminOrganisationCauses(
    String id,
    List<String> causeIds,
  ) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/admin/organisations/$id/causes'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'causeIds': causeIds}),
    );
    _ensureSuccess(response, 'Updating organisation causes');
  }

  Future<List<Map<String, dynamic>>> getAdminCauses() async {
    final response = await _client.get(Uri.parse('$baseUrl/admin/causes'));
    _ensureSuccess(response, 'Loading admin causes');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => item as Map<String, dynamic>)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createAdminCause(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/admin/causes'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureSuccess(response, 'Creating cause');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminCause(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/admin/causes/$id'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureSuccess(response, 'Updating cause');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setAdminCauseActive(
    String id,
    bool isActive,
  ) async {
    final action = isActive ? 'activate' : 'deactivate';
    final response = await _client.patch(
      Uri.parse('$baseUrl/admin/causes/$id/$action'),
      headers: const {'Content-Type': 'application/json'},
    );
    _ensureSuccess(response, 'Updating cause status');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _ensureSuccess(http.Response response, String operation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$operation failed: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}
