import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_events.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? _tryCreateAnalytics();

  static final AnalyticsService instance = AnalyticsService();
  static const _clientIdKey = 'analytics_client_id';
  static final String _sessionId = _randomId();

  final FirebaseAnalytics? _analytics;

  static FirebaseAnalytics? _tryCreateAnalytics() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAnalytics.instance;
  }

  FirebaseAnalyticsObserver? get observer => _analytics == null
      ? null
      : FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> trackScreen(String screenName, {String? screenClass}) async {
    final analytics = _analytics;
    if (analytics != null) {
      try {
        await analytics.logScreenView(
          screenName: screenName,
          screenClass: screenClass ?? screenName,
        );
      } catch (_) {}
    }
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
    final analytics = _analytics;
    if (analytics != null) {
      try {
        await analytics.logEvent(
          name: AnalyticsEvents.interaction,
          parameters: {
            AnalyticsParameters.screenName: screenName,
            AnalyticsParameters.interactionType: interactionType,
            AnalyticsParameters.target: target,
            ...?parameters,
          },
        );
      } catch (_) {}
    }
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
    final analytics = _analytics;
    if (analytics != null) {
      try {
        await analytics.logEvent(
          name: AnalyticsEvents.navigationSelect,
          parameters: {
            AnalyticsParameters.screenName: screenName,
            AnalyticsParameters.destination: destination,
            AnalyticsParameters.interactionType: AnalyticsInteractions.navigation,
          },
        );
      } catch (_) {}
    }
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
      final language = ui.PlatformDispatcher.instance.locale.languageCode;
      final deviceType = kIsWeb
          ? 'web'
          : switch (defaultTargetPlatform) {
              TargetPlatform.android => 'android',
              TargetPlatform.iOS => 'ios',
              TargetPlatform.macOS => 'macos',
              TargetPlatform.windows => 'windows',
              TargetPlatform.linux => 'linux',
              TargetPlatform.fuchsia => 'fuchsia',
            };
      final city = const String.fromEnvironment('ANALYTICS_CITY');
      await http.post(
        Uri.parse('$baseUrl/analytics/events'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
          'sessionId': _sessionId,
          'eventName': eventName,
          'screenName': screenName,
          'language': language,
          'deviceType': deviceType,
          if (city.isNotEmpty) 'city': city,
          if (interactionType != null) 'interactionType': interactionType,
          if (target != null) 'target': target,
        }),
      );
    } catch (_) {}
  }

  static String _randomId() => List<int>.generate(
        16,
        (_) => Random.secure().nextInt(256),
      ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}
