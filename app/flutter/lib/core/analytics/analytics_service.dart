import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../service_window.dart';
import 'analytics_events.dart';

class AnalyticsService {
  AnalyticsService({
    FirebaseAnalytics? analytics,
    http.Client? client,
    Duration? flushInterval,
    int? batchSize,
  })  : _analytics = analytics ?? _tryCreateAnalytics(),
        _client = client ?? http.Client(),
        _flushInterval = flushInterval ?? const Duration(seconds: 15),
        _batchSize = batchSize ?? 25;

  static final AnalyticsService instance = AnalyticsService();
  static const _clientIdKey = 'analytics_client_id';
  static final String _sessionId = _randomId();
  static const _maxQueueSize = 250;
  static const _batchEndpoint = '/analytics/events/batch';

  final FirebaseAnalytics? _analytics;
  final http.Client _client;
  final Duration _flushInterval;
  final int _batchSize;
  final List<Map<String, dynamic>> _queue = <Map<String, dynamic>>[];
  Timer? _flushTimer;
  Future<String>? _clientIdFuture;
  bool _flushInProgress = false;

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
    await _enqueue(
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
    await _enqueue(
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
    await _enqueue(
      eventName: AnalyticsEvents.navigationSelect,
      screenName: screenName,
      interactionType: AnalyticsInteractions.navigation,
      target: destination,
    );
  }

  Future<void> _enqueue({
    required String eventName,
    required String screenName,
    String? interactionType,
    String? target,
  }) async {
    try {
      final clientId = await (_clientIdFuture ??= _loadClientId());
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

      if (_queue.length >= _maxQueueSize) {
        _queue.removeRange(0, _queue.length - _maxQueueSize + 1);
      }
      _queue.add({
        'clientId': clientId,
        'sessionId': _sessionId,
        'eventName': eventName,
        'screenName': screenName,
        'language': language,
        'deviceType': deviceType,
        'city': city,
        ...?interactionType == null ? null : {'interactionType': interactionType},
        ...?target == null ? null : {'target': target},
      });

      if (_queue.length >= _batchSize) {
        unawaited(flush());
      } else {
        _flushTimer ??= Timer(_flushInterval, () {
          _flushTimer = null;
          unawaited(flush());
        });
      }
    } catch (_) {}
  }

  Future<void> flush() async {
    if (_flushInProgress || _queue.isEmpty || BackendServiceAvailability.isDowntime) {
      return;
    }
    _flushInProgress = true;
    try {
      final baseUrl = const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ).replaceFirst(RegExp(r'/$'), '');

      while (_queue.isNotEmpty && !BackendServiceAvailability.isDowntime) {
        final count = _queue.length < _batchSize ? _queue.length : _batchSize;
        final batch = List<Map<String, dynamic>>.from(_queue.take(count));
        try {
          final response = await _client.post(
            Uri.parse('$baseUrl$_batchEndpoint'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'events': batch}),
          );
          if (response.statusCode < 200 || response.statusCode >= 300) {
            break;
          }
          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic> ||
              decoded['accepted'] != true ||
              decoded['acceptedCount'] != batch.length) {
            break;
          }
          _queue.removeRange(0, batch.length);
        } catch (_) {
          break;
        }
      }
    } finally {
      _flushInProgress = false;
      if (_queue.isNotEmpty && !BackendServiceAvailability.isDowntime) {
        _flushTimer ??= Timer(_flushInterval, () {
          _flushTimer = null;
          unawaited(flush());
        });
      }
    }
  }

  Future<String> _loadClientId() async {
    final preferences = await SharedPreferences.getInstance();
    var clientId = preferences.getString(_clientIdKey);
    if (clientId == null || clientId.isEmpty) {
      clientId = _randomId();
      await preferences.setString(_clientIdKey, clientId);
    }
    return clientId;
  }

  static String _randomId() => List<int>.generate(
        16,
        (_) => Random.secure().nextInt(256),
      ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();

  void dispose() {
    _flushTimer?.cancel();
    _client.close();
  }
}
