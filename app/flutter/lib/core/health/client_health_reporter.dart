import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClientHealthReporter {
  ClientHealthReporter({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _clientIdKey = 'health_client_id';
  static final String _sessionId = _randomId();

  Future<void> report({required String type, required Object error, StackTrace? stack}) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      var clientId = preferences.getString(_clientIdKey);
      if (clientId == null || clientId.isEmpty) {
        clientId = _randomId();
        await preferences.setString(_clientIdKey, clientId);
      }
      final baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000').replaceFirst(RegExp(r'/$'), '');
      final message = error.toString();
      final stackText = stack?.toString();
      await _client.post(
        Uri.parse('$baseUrl/platform-health/client-events'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
          'sessionId': _sessionId,
          'type': type,
          'message': message.substring(0, min(500, message.length)),
          if (stackText != null) 'stack': stackText.substring(0, min(4000, stackText.length)),
        }),
      );
    } catch (_) {
      // Error telemetry must never block or replace the original app error.
    }
  }

  static String _randomId() => List<int>.generate(16, (_) => Random.secure().nextInt(256)).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}
