import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_events.dart';

/// Application-level analytics facade.
///
/// Feature code should use this service instead of depending directly on
/// Firebase Analytics. This keeps the event taxonomy centralized and makes
/// future analytics providers or collection policies easier to introduce.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  static final AnalyticsService instance = AnalyticsService();

  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> trackScreen(
    String screenName, {
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
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
    final eventParameters = <String, Object>{
      AnalyticsParameters.screenName: screenName,
      AnalyticsParameters.interactionType: interactionType,
      AnalyticsParameters.target: target,
      ...?parameters,
    };

    await _analytics.logEvent(
      name: AnalyticsEvents.interaction,
      parameters: eventParameters,
    );
  }

  Future<void> trackNavigation({
    required String destination,
    required String screenName,
  }) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.navigationSelect,
      parameters: {
        AnalyticsParameters.screenName: screenName,
        AnalyticsParameters.destination: destination,
        AnalyticsParameters.interactionType: AnalyticsInteractions.navigation,
      },
    );
  }
}
