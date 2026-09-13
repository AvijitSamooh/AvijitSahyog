import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/admin_analytics_summary.dart';

class AdminAnalyticsRepository {
  AdminAnalyticsRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<AdminAnalyticsSummary> getSummary() async {
    final baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000').replaceFirst(RegExp(r'/$'), '');
    final user = FirebaseAuth.instance.currentUser;
    final token = user == null ? null : await user.getIdToken();
    final response = await _client.get(Uri.parse('$baseUrl/admin/dashboard/analytics'), headers: {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'});
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Loading analytics failed: ${response.statusCode}');
    return AdminAnalyticsSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  void dispose() => _client.close();
}
