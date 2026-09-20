import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:avijit_sahyog/core/network/api_client.dart';

void main() {
  test('protected admin requests include the Firebase bearer token', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer firebase-token');
      return http.Response('[]', 200);
    });

    final api = ApiClient(
      client: client,
      baseUrl: 'https://api.example.com',
      authTokenProvider: () async => 'firebase-token',
    );

    await api.getAdminCauses();
    api.dispose();
  });

  test('protected application history requests include the Firebase bearer token', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/applications/mine');
      expect(request.headers['authorization'], 'Bearer firebase-token');
      return http.Response('[]', 200);
    });

    final api = ApiClient(
      client: client,
      baseUrl: 'https://api.example.com',
      authTokenProvider: () async => 'firebase-token',
    );

    await api.getMyHelpApplications();
    api.dispose();
  });
  test('protected application deletion requests include the Firebase bearer token', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/applications/mine/app-1');
      expect(request.headers['authorization'], 'Bearer firebase-token');
      return http.Response('', 204);
    });

    final api = ApiClient(
      client: client,
      baseUrl: 'https://api.example.com',
      authTokenProvider: () async => 'firebase-token',
    );

    await api.deleteMyHelpApplication('app-1');
    api.dispose();
  });

  test('tracks every in-flight backend request and clears after completion', () async {
    final completer = Completer<http.Response>();
    final client = MockClient((request) => completer.future);
    final api = ApiClient(client: client, baseUrl: 'https://api.example.com');

    final future = api.createDonation({'amount': 100});
    await Future<void>.delayed(Duration.zero);
    expect(ApiClient.activeRequests.value, 1);

    completer.complete(http.Response('{"id":"donation-1"}', 200));
    await future;
    expect(ApiClient.activeRequests.value, 0);
    api.dispose();
  });
}
