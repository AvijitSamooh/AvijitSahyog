import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? _tryCreateAnalytics();

  static final AnalyticsService instance = AnalyticsService();

  final FirebaseAnalytics? _analytics;

  static FirebaseAnalytics? _tryCreateAnalytics() {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseAnalytics.instance;
  }

  FirebaseAnalyticsObserver? get observer => _analytics == null
      ? null
      : FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> trackScreen(
    String screenName, {
    String? screenClass,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  Future<void> trackInteraction(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  Future<void> trackNavigation(
    String destination, {
    String? source,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(
      name: 'navigation',
      parameters: {
        'destination': destination,
        if (source != null) 'source': source,
      },
    );
  }
}
