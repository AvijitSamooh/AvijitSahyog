import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/applications/data/help_applications_repository.dart';

void main() {
  test('loads application history when Prisma Decimal amounts are JSON strings', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/applications/mine');
      return http.Response(
        jsonEncode([
          {
            'id': 'app-1',
            'type': 'MEDICAL_HELP',
            'status': 'SUBMITTED',
            'applicantName': 'Test User',
            'mobileNumber': '9876543210',
            'requestedAmount': '25000.00',
            'approvedAmount': '12500.00',
            'media': <dynamic>[],
          },
        ]),
        200,
      );
    });
    final api = ApiClient(client: client, baseUrl: 'https://api.example.com');
    final repository = HelpApplicationsRepository(api);

    final applications = await repository.mine();

    expect(applications, hasLength(1));
    expect(applications.single.id, 'app-1');
    expect(applications.single.requestedAmount, 25000);
    expect(applications.single.approvedAmount, 12500);
    api.dispose();
  });
}
