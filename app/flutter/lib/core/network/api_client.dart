import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    http.Client? client,
    this.baseUrl = 'http://localhost:3000',
  }) : _client = client ?? http.Client();

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

  void _ensureSuccess(http.Response response, String operation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$operation failed: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}
