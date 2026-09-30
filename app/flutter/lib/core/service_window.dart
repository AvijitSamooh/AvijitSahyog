class ServiceWindow {
  const ServiceWindow({
    required this.enabled,
    required this.startMinutes,
    required this.endMinutes,
    required this.startLabel,
    required this.endLabel,
  });

  final bool enabled;
  final int startMinutes;
  final int endMinutes;
  final String startLabel;
  final String endLabel;

  factory ServiceWindow.fromEnvironment() {
    const enabled = bool.fromEnvironment(
      'BACKEND_SERVICE_WINDOW_ENABLED',
      defaultValue: true,
    );
    const startLabel = String.fromEnvironment(
      'BACKEND_SERVICE_WINDOW_START',
      defaultValue: '21:00',
    );
    const endLabel = String.fromEnvironment(
      'BACKEND_SERVICE_WINDOW_END',
      defaultValue: '08:00',
    );

    return ServiceWindow.fromLabels(
      enabled: enabled,
      startLabel: startLabel,
      endLabel: endLabel,
    );
  }

  factory ServiceWindow.fromLabels({
    required bool enabled,
    required String startLabel,
    required String endLabel,
  }) {
    var startMinutes = _parseMinutes(startLabel, fallback: 21 * 60);
    var endMinutes = _parseMinutes(endLabel, fallback: 8 * 60);

    // The configured production window is an overnight offline window.
    // Normalize an accidentally reversed daytime configuration so an old or
    // misconfigured build cannot disable the backend during the daytime.
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
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return fallback;
    }

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
  String toString() =>
      'Backend service is unavailable from ${window.startLabel} to ${window.endLabel}.';
}

class BackendServiceAvailability {
  BackendServiceAvailability._();

  static final ServiceWindow window = ServiceWindow.fromEnvironment();

  static bool get isDowntime => window.isDowntime(DateTime.now());

  static void ensureAvailable() {
    if (isDowntime) {
      throw BackendServiceUnavailableException(window);
    }
  }

  static String get startLabel => window.startLabel;
  static String get endLabel => window.endLabel;
}
