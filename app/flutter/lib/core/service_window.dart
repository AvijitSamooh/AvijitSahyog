import 'dart:convert';
import 'package:http/http.dart' as http;

class ServiceWindow {
  const ServiceWindow({
    required this.enabled,
    required this.startMinutes,
    required this.endMinutes,
    required this.startLabel,
    required this.endLabel,
    this.message,
  });

  final bool enabled;
  final int startMinutes;
  final int endMinutes;
  final String startLabel;
  final String endLabel;
  final String? message;

  factory ServiceWindow.fromEnvironment() {
    const enabled = bool.fromEnvironment('BACKEND_SERVICE_WINDOW_ENABLED', defaultValue: false);
    const startLabel = String.fromEnvironment('BACKEND_SERVICE_OFFLINE_START', defaultValue: '21:00');
    const endLabel = String.fromEnvironment('BACKEND_SERVICE_OFFLINE_END', defaultValue: '08:00');
    return ServiceWindow.fromLabels(enabled: enabled, startLabel: startLabel, endLabel: endLabel);
  }

  factory ServiceWindow.fromLabels({
    required bool enabled,
    required String startLabel,
    required String endLabel,
    String? message,
  }) {
    var startMinutes = _parseMinutes(startLabel, fallback: 21 * 60);
    var endMinutes = _parseMinutes(endLabel, fallback: 8 * 60);
    if (startMinutes < endMinutes) {
      final normalizedStart = startMinutes;
      startMinutes = endMinutes;
      endMinutes = normalizedStart;
    }
    return ServiceWindow(
      enabled: enabled,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      startLabel: _displayTime(startMinutes),
      endLabel: _displayTime(endMinutes),
      message: message,
    );
  }

  bool isDowntime(DateTime now) {
    if (!enabled) return false;
    final minutes = now.hour * 60 + now.minute;
    if (startMinutes == endMinutes) return true;
    if (startMinutes > endMinutes) {
      return minutes >= startMinutes || minutes < endMinutes;
    }
    return minutes >= startMinutes && minutes < endMinutes;
  }

  static int _parseMinutes(String value, {required int fallback}) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return fallback;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) return fallback;
    return hour * 60 + minute;
  }

  static String _displayTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

class BackendServiceUnavailableException implements Exception {
  const BackendServiceUnavailableException(this.window);
  final ServiceWindow window;

  @override
  String toString() => window.message?.isNotEmpty == true
      ? window.message!
      : 'Backend service is unavailable from ${window.startLabel} to ${window.endLabel}.';
}

class BackendServiceAvailability {
  BackendServiceAvailability._();

  static ServiceWindow _window = ServiceWindow.fromEnvironment();
  static ServiceWindow get window => _window;

  static bool get isDowntime => _window.isDowntime(DateTime.now());

  static Future<void> loadRemote(String baseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/platform-downtime'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return;
      _window = ServiceWindow.fromLabels(
        enabled: data['enabled'] == true,
        startLabel: data['startTime']?.toString() ?? '21:00',
        endLabel: data['endTime']?.toString() ?? '08:00',
        message: data['message']?.toString(),
      );
    } catch (_) {
      // A network failure must not prevent the app from starting or signing in.
    }
  }

  static void applyRemote(Map<String, dynamic> data) {
    _window = ServiceWindow.fromLabels(
      enabled: data['enabled'] == true,
      startLabel: data['startTime']?.toString() ?? '21:00',
      endLabel: data['endTime']?.toString() ?? '08:00',
      message: data['message']?.toString(),
    );
  }

  static void ensureAvailable({String? path}) {
    if (!isDowntime) return;
    final normalized = path ?? '';
    // Authentication and the downtime control plane must remain reachable.
    if (normalized.startsWith('/auth/') || normalized == '/platform-downtime') return;
    throw BackendServiceUnavailableException(_window);
  }

  static String get startLabel => _window.startLabel;
  static String get endLabel => _window.endLabel;
}
