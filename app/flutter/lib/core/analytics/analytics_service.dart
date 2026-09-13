import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import 'analytics_events.dart';

/// Application-level analytics facade.
///
/// Feature code should use this service instead of depending directly on
/// Firebase Analytics. This keeps the event taxonomy centralized and makes
/// future analytics providers or collection policies easier to introduce.
///
/// Analytics is optional until Firebase has been initialized. This is useful
/// for widget tests and for app startup paths where Firebase configuration is
/// not yet available; feature UI must not fail just because analytics is
/// unavailable.
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
      : FirebaseAnalyticsObserver(analytics: _analytics!);

  Future<void> trackScreen(
    String screenName, {
    String? screenClass,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;

    await analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  Future<void> trackInteraction({
    required String screenName,
    required String target,
    String interactionType = AnalyticsInteractions.tap,
    Map<String, Object>? parameters,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;

    final eventParameters = <String, Object>{
      AnalyticsParameters.screenName: screenName,
      AnalyticsParameters.interactionType: interactionType,
      AnalyticsParameters.target: target,
      ...?parameters,
    };

    await analytics.logEvent(
      name: AnalyticsEvents.interaction,
      parameters: eventParameters,
    );
  }

  Future<void> trackNavigation({
    required String destination,
    required String screenName,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;

    await analytics.logEvent(
      name: AnalyticsEvents.navigationSelect,
      parameters: {
        AnalyticsParameters.screenName: screenName,
        AnalyticsParameters.destination: destination,
        AnalyticsParameters.interactionType: AnalyticsInteractions.navigation,
      },
    );
  }
}
