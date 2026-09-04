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
}
