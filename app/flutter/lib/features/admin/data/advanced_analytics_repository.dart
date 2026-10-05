import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/advanced_analytics_summary.dart';

class AdvancedAnalyticsRepository {
  AdvancedAnalyticsRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<AdvancedAnalyticsSummary> getSummary() async {
    final baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000').replaceFirst(RegExp(r'/$'), '');
    final user = FirebaseAuth.instance.currentUser;
    final token = user == null ? null : await user.getIdToken();
    final response = await _client.get(Uri.parse('$baseUrl/admin/dashboard/analytics/advanced'), headers: {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'});
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Loading advanced analytics failed: ${response.statusCode}');
    return AdvancedAnalyticsSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}
