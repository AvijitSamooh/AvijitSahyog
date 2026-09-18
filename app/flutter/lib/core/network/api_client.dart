import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this._authTokenProvider,
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
  final Future<String?> Function()? _authTokenProvider;
  final String baseUrl;

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _authTokenProvider?.call();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getHealth() async {
    final response = await _client.get(Uri.parse('$baseUrl/health'));
    _ensureSuccess(response, 'Health check');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCauses(String languageCode) async {
    final uri = Uri.parse('$baseUrl/causes').replace(queryParameters: {'language': languageCode});
    final response = await _client.get(uri);
    _ensureSuccess(response, 'Loading causes');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((item) => item as Map<String, dynamic>).toList(growable: false);
  }

  Future<Map<String, dynamic>> getCause(String slug, String languageCode) async {
    final uri = Uri.parse('$baseUrl/causes/$slug').replace(queryParameters: {'language': languageCode});
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

  Future<Map<String, dynamic>> createDonation(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/donations'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureSuccess(response, 'Creating donation');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadAdminImage(String path) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/admin/media/upload'))
      ..headers.addAll(await _headers())
      ..files.add(await http.MultipartFile.fromPath('file', path));
    final response = await http.Response.fromStream(await request.send());
    _ensureSuccess(response, 'Uploading image');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAdminEntityMedia(String entity, String id) async {
    final response = await _client.get(Uri.parse('$baseUrl/admin/$entity/$id/media'), headers: await _headers());
    _ensureSuccess(response, 'Loading media');
    return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> attachAdminEntityMedia(String entity, String id, Map<String, dynamic> payload) async {
    final response = await _client.post(Uri.parse('$baseUrl/admin/$entity/$id/media'),
      headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Attaching media');
  }

  Future<void> removeAdminEntityMedia(String entity, String id, String mediaId) async {
    final response = await _client.delete(Uri.parse('$baseUrl/admin/$entity/$id/media/$mediaId'), headers: await _headers());
    _ensureSuccess(response, 'Removing media');
  }

  Future<Map<String, dynamic>> getAdminDashboardSummary() async {
    final response = await _client.get(Uri.parse('$baseUrl/admin/dashboard'), headers: await _headers());
    _ensureSuccess(response, 'Loading admin dashboard');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminUsers({
    String? search,
    String role = 'ADMIN',
    int page = 1,
    int pageSize = 3,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/users').replace(queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'role': role,
      'page': '$page',
      'pageSize': '$pageSize',
    });
    final response = await _client.get(uri, headers: await _headers());
    _ensureSuccess(response, 'Loading admin users');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> makeAdmin(String userId, {String role = 'ADMIN'}) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/admin/users/$userId/role'),
      headers: await _headers(json: true),
      body: jsonEncode({'role': role}),
    );
    _ensureSuccess(response, 'Changing administrator role');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAdminAuditHistory() async {
    final response = await _client.get(Uri.parse('$baseUrl/admin/users/audit-history'), headers: await _headers());
    _ensureSuccess(response, 'Loading audit history');
    return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdminBeneficiaries() async {
    final response = await _client.get(Uri.parse('$baseUrl/admin/beneficiaries'), headers: await _headers());
    _ensureSuccess(response, 'Loading admin beneficiaries');
    return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAdminBeneficiary(Map<String, dynamic> payload) async {
    final response = await _client.post(Uri.parse('$baseUrl/admin/beneficiaries'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Creating beneficiary');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminBeneficiary(String id, Map<String, dynamic> payload) async {
    final response = await _client.patch(Uri.parse('$baseUrl/admin/beneficiaries/$id'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Updating beneficiary');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteAdminBeneficiary(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/admin/beneficiaries/$id'),
      headers: await _headers(),
    );
    _ensureSuccess(response, 'Deleting beneficiary');
  }

  Future<void> setAdminBeneficiaryActive(String id, bool active) async {
    final action = active ? 'activate' : 'deactivate';
    final response = await _client.patch(Uri.parse('$baseUrl/admin/beneficiaries/$id/$action'), headers: await _headers());
    _ensureSuccess(response, 'Updating beneficiary status');
  }

  Future<List<Map<String, dynamic>>> getAdminOrganisations() async {
    final response = await _client.get(Uri.parse('$baseUrl/admin/organisations'), headers: await _headers());
    _ensureSuccess(response, 'Loading admin organisations');
    return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAdminOrganisation(Map<String, dynamic> payload) async {
    final response = await _client.post(Uri.parse('$baseUrl/admin/organisations'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Creating organisation');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminOrganisation(String id, Map<String, dynamic> payload) async {
    final response = await _client.patch(Uri.parse('$baseUrl/admin/organisations/$id'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Updating organisation');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> setAdminOrganisationActive(String id, bool active) async {
    final action = active ? 'activate' : 'deactivate';
    final response = await _client.patch(Uri.parse('$baseUrl/admin/organisations/$id/$action'), headers: await _headers());
    _ensureSuccess(response, 'Updating organisation status');
  }

  Future<void> updateAdminOrganisationCauses(String id, List<String> causeIds) async {
    final response = await _client.patch(Uri.parse('$baseUrl/admin/organisations/$id/causes'), headers: await _headers(json: true), body: jsonEncode({'causeIds': causeIds}));
    _ensureSuccess(response, 'Updating organisation causes');
  }

  Future<List<Map<String, dynamic>>> getAdminCauses() async {
    final response = await _client.get(Uri.parse('$baseUrl/admin/causes'), headers: await _headers());
    _ensureSuccess(response, 'Loading admin causes');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((item) => item as Map<String, dynamic>).toList(growable: false);
  }

  Future<Map<String, dynamic>> createAdminCause(Map<String, dynamic> payload) async {
    final response = await _client.post(Uri.parse('$baseUrl/admin/causes'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Creating cause');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminCause(String id, Map<String, dynamic> payload) async {
    final response = await _client.patch(Uri.parse('$baseUrl/admin/causes/$id'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Updating cause');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setAdminCauseActive(String id, bool isActive) async {
    final action = isActive ? 'activate' : 'deactivate';
    final response = await _client.patch(Uri.parse('$baseUrl/admin/causes/$id/$action'), headers: await _headers(json: true));
    _ensureSuccess(response, 'Updating cause status');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadApplicationImage(String path) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/media/upload'))
      ..headers.addAll(await _headers())
      ..files.add(await http.MultipartFile.fromPath('file', path));
    final response = await http.Response.fromStream(await request.send());
    _ensureSuccess(response, 'Uploading supporting image');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createHelpApplication(Map<String, dynamic> payload) async {
    final response = await _client.post(Uri.parse('$baseUrl/applications'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Submitting application');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMyHelpApplications() async {
    final response = await _client.get(Uri.parse('$baseUrl/applications/mine'), headers: await _headers());
    _ensureSuccess(response, 'Loading applications');
    return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getMyHelpApplication(String id) async {
    final response = await _client.get(Uri.parse('$baseUrl/applications/mine/$id'), headers: await _headers());
    _ensureSuccess(response, 'Loading application');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resubmitHelpApplication(String id, Map<String, dynamic> payload) async {
    final response = await _client.patch(Uri.parse('$baseUrl/applications/mine/$id/resubmit'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Resubmitting application');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAdminHelpApplications({String? type, String? status}) async {
    final uri = Uri.parse('$baseUrl/admin/applications').replace(queryParameters: {
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    final response = await _client.get(uri, headers: await _headers());
    _ensureSuccess(response, 'Loading applications');
    return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> voteHelpApplication(String id, int score, {String? comment}) async {
    final response = await _client.post(Uri.parse('$baseUrl/admin/applications/$id/vote'), headers: await _headers(json: true), body: jsonEncode({'score': score, 'comment': ?comment}));
    _ensureSuccess(response, 'Saving application vote');
  }

  Future<Map<String, dynamic>> reviewHelpApplication(String id, Map<String, dynamic> payload) async {
    final response = await _client.patch(Uri.parse('$baseUrl/admin/applications/$id/review'), headers: await _headers(json: true), body: jsonEncode(payload));
    _ensureSuccess(response, 'Reviewing application');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _ensureSuccess(http.Response response, String operation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.trim();
      var detail = body;
      if (body.isNotEmpty) {
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            final message = decoded['message'];
            detail = message is List ? message.join(', ') : (message?.toString() ?? body);
          }
        } catch (_) {
          // Keep the raw response body when it is not JSON.
        }
      }
      throw Exception('$operation failed: ${response.statusCode}${detail.isEmpty ? '' : ': $detail'}');
    }
  }

  void dispose() {
    _client.close();
  }
}
