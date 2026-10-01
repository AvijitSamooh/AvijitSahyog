import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/service_window.dart';
import '../models/cause.dart';

class CausesRepository {
  CausesRepository(
    this._apiClient, {
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider =
            preferencesProvider ?? SharedPreferences.getInstance;

  static const _cachePrefix = 'causes_cache_v1_';
  static const _freshDuration = Duration(hours: 1);
  static const _staleDuration = Duration(days: 30);

  final ApiClient _apiClient;
  final Future<SharedPreferences> Function() _preferencesProvider;

  Future<List<Cause>> getCauses(String languageCode) async {
    final key = '$_cachePrefix$languageCode';
    final cached = await _readCache(key);
    if (cached != null && cached.isFresh) {
      return _decodeList(cached.payload);
    }

    if (BackendServiceAvailability.isDowntime && cached != null) {
      return _decodeList(cached.payload);
    }

    try {
      final data = await _apiClient.getCauses(languageCode);
      await _writeCache(key, data);
      return data.map((item) => Cause.fromJson(item)).toList(growable: false);
    } catch (_) {
      if (cached != null) {
        return _decodeList(cached.payload);
      }
      rethrow;
    }
  }

  Future<Cause> getCause(String slug, String languageCode) async {
    final key = '$_cachePrefix$languageCode-$slug';
    final cached = await _readCache(key);
    if (cached != null && cached.isFresh) {
      return Cause.fromJson(cached.payload as Map<String, dynamic>);
    }

    if (BackendServiceAvailability.isDowntime && cached != null) {
      return Cause.fromJson(cached.payload as Map<String, dynamic>);
    }

    try {
      final data = await _apiClient.getCause(slug, languageCode);
      await _writeCache(key, data);
      return Cause.fromJson(data);
    } catch (_) {
      if (cached != null) {
        return Cause.fromJson(cached.payload as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  List<Cause> _decodeList(dynamic payload) {
    return (payload as List<dynamic>)
        .map((item) => Cause.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<_CachedCausePayload?> _readCache(String key) async {
    final preferences = await _preferencesProvider();
    final encoded = preferences.getString(key);
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(decoded['savedAt'] as String? ?? '');
      final payload = decoded['payload'];
      if (savedAt == null || payload == null) return null;
      final age = DateTime.now().difference(savedAt);
      if (age > _staleDuration) return null;
      return _CachedCausePayload(payload, age <= _freshDuration);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, dynamic payload) async {
    final preferences = await _preferencesProvider();
    await preferences.setString(
      key,
      jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'payload': payload,
      }),
    );
  }
}

class _CachedCausePayload {
  const _CachedCausePayload(this.payload, this.isFresh);

  final dynamic payload;
  final bool isFresh;
}
