import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PlatformHealthRepository {
  PlatformHealthRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<PlatformHealthSummary> getSummary() async {
    final baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000').replaceFirst(RegExp(r'/$'), '');
    final user = FirebaseAuth.instance.currentUser;
    final token = user == null ? null : await user.getIdToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/platform-health/summary'),
      headers: {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Loading platform health failed: ${response.statusCode}');
    }
    return PlatformHealthSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}

class PlatformHealthSummary {
  const PlatformHealthSummary({required this.status, required this.database, required this.api, required this.deployment, required this.errors24h, required this.authFailures24h, required this.uploadFailures24h, required this.appErrors24h, required this.crashes24h, required this.last7Days, required this.recentEvents});
  final String status;
  final String database;
  final PlatformHealthApi api;
  final PlatformDeploymentInfo deployment;
  final int errors24h, authFailures24h, uploadFailures24h, appErrors24h, crashes24h;
  final Map<String, int> last7Days;
  final List<PlatformHealthEvent> recentEvents;

  factory PlatformHealthSummary.fromJson(Map<String, dynamic> json) => PlatformHealthSummary(
    status: json['status'] as String,
    database: json['database'] as String,
    api: PlatformHealthApi.fromJson(json['api'] as Map<String, dynamic>),
    deployment: PlatformDeploymentInfo.fromJson(json['deployment'] as Map<String, dynamic>),
    errors24h: (json['errors24h'] as num).toInt(),
    authFailures24h: (json['authFailures24h'] as num).toInt(),
    uploadFailures24h: (json['uploadFailures24h'] as num).toInt(),
    appErrors24h: (json['appErrors24h'] as num).toInt(),
    crashes24h: (json['crashes24h'] as num).toInt(),
    last7Days: (json['last7Days'] as Map<String, dynamic>).map((key, value) => MapEntry(key, (value as num).toInt())),
    recentEvents: (json['recentEvents'] as List<dynamic>).map((item) => PlatformHealthEvent.fromJson(item as Map<String, dynamic>)).toList(growable: false),
  );
}

class PlatformHealthApi {
  const PlatformHealthApi({required this.status, required this.uptimeSeconds});
  final String status;
  final int uptimeSeconds;
  factory PlatformHealthApi.fromJson(Map<String, dynamic> json) => PlatformHealthApi(status: json['status'] as String, uptimeSeconds: (json['uptimeSeconds'] as num).toInt());
}

class PlatformDeploymentInfo {
  const PlatformDeploymentInfo({required this.environment, required this.version, required this.deploymentId, required this.gitSha, required this.deployedAt});
  final String environment, version, deploymentId, gitSha;
  final String? deployedAt;
  factory PlatformDeploymentInfo.fromJson(Map<String, dynamic> json) => PlatformDeploymentInfo(environment: json['environment'] as String, version: json['version'] as String, deploymentId: json['deploymentId'] as String, gitSha: json['gitSha'] as String, deployedAt: json['deployedAt'] as String?);
}

class PlatformHealthEvent {
  const PlatformHealthEvent({required this.id, required this.type, required this.statusCode, required this.route, required this.method, required this.message, required this.createdAt});
  final String id, type;
  final int? statusCode;
  final String? route, method, message;
  final String createdAt;
  factory PlatformHealthEvent.fromJson(Map<String, dynamic> json) => PlatformHealthEvent(id: json['id'] as String, type: json['type'] as String, statusCode: (json['statusCode'] as num?)?.toInt(), route: json['route'] as String?, method: json['method'] as String?, message: json['message'] as String?, createdAt: json['createdAt'] as String);
}
