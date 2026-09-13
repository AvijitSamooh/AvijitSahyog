import 'dart:convert';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_events.dart';

/// Application-level analytics facade.
///
/// Firebase remains the primary analytics provider. A privacy-conscious event
/// stream is also mirrored to the application backend for the Super Admin
/// engagement dashboard. No PII is sent in analytics parameters.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics, http.Client? client})
      : _analytics = analytics ?? FirebaseAnalytics.instance,
        _client = client ?? http.Client();

  static final AnalyticsService instance = AnalyticsService();
  static const _clientIdKey = 'analytics_client_id';
  static final String _sessionId = _randomId();

  final FirebaseAnalytics _analytics;
  final http.Client _client;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> trackScreen(String screenName, {String? screenClass}) async {
    await _safeFirebase(() => _analytics.logScreenView(
          screenName: screenName,
          screenClass: screenClass ?? screenName,
        ));
    await _mirror(
      eventName: AnalyticsEvents.screenView,
      screenName: screenName,
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
    await _safeFirebase(() => _analytics.logEvent(
          name: AnalyticsEvents.interaction,
          parameters: eventParameters,
        ));
    await _mirror(
      eventName: AnalyticsEvents.interaction,
      screenName: screenName,
      interactionType: interactionType,
      target: target,
    );
  }

  Future<void> trackNavigation({
    required String destination,
    required String screenName,
  }) async {
    await _safeFirebase(() => _analytics.logEvent(
          name: AnalyticsEvents.navigationSelect,
          parameters: {
            AnalyticsParameters.screenName: screenName,
            AnalyticsParameters.destination: destination,
            AnalyticsParameters.interactionType: AnalyticsInteractions.navigation,
          },
        ));
    await _mirror(
      eventName: AnalyticsEvents.navigationSelect,
      screenName: screenName,
      interactionType: AnalyticsInteractions.navigation,
      target: destination,
    );
  }

  Future<void> _mirror({
    required String eventName,
    required String screenName,
    String? interactionType,
    String? target,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      var clientId = preferences.getString(_clientIdKey);
      if (clientId == null || clientId.isEmpty) {
        clientId = _randomId();
        await preferences.setString(_clientIdKey, clientId);
      }
      final baseUrl = const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ).replaceFirst(RegExp(r'/$'), '');
      await _client.post(
        Uri.parse('$baseUrl/analytics/events'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
          'sessionId': _sessionId,
          'eventName': eventName,
          'screenName': screenName,
          if (interactionType != null) 'interactionType': interactionType,
          if (target != null) 'target': target,
        }),
      );
    } catch (_) {
      // Analytics must never affect the user flow.
    }
  }

  Future<void> _safeFirebase(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Analytics must never affect the user flow.
    }
  }

  static String _randomId() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
