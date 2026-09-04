import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import 'package:avijit_sahyog/core/network/api_client.dart';

void main() {
  test('protected admin requests include the Firebase bearer token', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer firebase-token');
      return stringResponse('[]');
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
