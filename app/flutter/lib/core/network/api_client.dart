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

    if (response.statusCode != 200) {
      throw Exception(
        'Health check failed: ${response.statusCode}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() {
    _client.close();
  }
}