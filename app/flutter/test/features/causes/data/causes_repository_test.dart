import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/causes/data/causes_repository.dart';

class _FakeClient extends http.BaseClient {
  int getCalls = 0;
  bool fail = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    getCalls++;
    if (fail) {
      throw Exception('backend unavailable');
    }
    return http.StreamedResponse(
      Stream.value(
        '[{"id":"cause-1","slug":"jeev-daya","name":"Jeev Daya","description":"Animal welfare","displayOrder":1,"children":[]}]',
      ).cast(),
      200,
      request: request,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('serves a fresh cached cause list without another HTTP read', () async {
    final client = _FakeClient();
    final api = ApiClient(client: client, baseUrl: 'https://example.test');
    final repository = CausesRepository(api);

    final first = await repository.getCauses('en');
    final second = await repository.getCauses('en');

    expect(first.single.description, 'Animal welfare');
    expect(second.single.slug, 'jeev-daya');
    expect(client.getCalls, 1);
  });

  test('returns cached causes when the backend becomes unavailable', () async {
    final client = _FakeClient();
    final api = ApiClient(client: client, baseUrl: 'https://example.test');
    final repository = CausesRepository(api);

    await repository.getCauses('en');
    client.fail = true;

    final cached = await repository.getCauses('en');

    expect(cached.single.name, 'Jeev Daya');
    expect(client.getCalls, 1);
  });
}
