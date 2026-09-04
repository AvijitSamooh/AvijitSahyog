import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/impact/models/beneficiary.dart';

void main() {
  test('beneficiary model parses API response and numeric amount', () {
    final beneficiary = Beneficiary.fromJson({
      'id': 'b-1',
      'name': 'Rahul Kumar',
      'supportedYear': 2025,
      'contributionAmount': '25000.00',
      'cause': {'id': 'c-1', 'slug': 'education'},
      'organisation': {'id': 'o-1', 'slug': 'demo-education'},
      'profileImage': {'id': 'm-1', 'url': 'https://images.example.com/profile.webp'},
      'gallery': [
        {'id': 'm-2', 'url': 'https://images.example.com/gallery-1.webp'},
        {'id': 'm-3', 'url': 'https://images.example.com/gallery-2.webp'},
      ],
    });

    expect(beneficiary.cause, 'education');
    expect(beneficiary.organisationName, 'demo-education');
    expect(beneficiary.contributionAmount, 25000);
    expect(beneficiary.primaryImageUrl, 'https://images.example.com/profile.webp');
    expect(beneficiary.gallery, hasLength(2));
  });

  test('beneficiaries API sends search and sort query parameters', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(jsonEncode([]), 200);
    });
    final api = ApiClient(client: client, baseUrl: 'https://api.example.com/');

    await api.getBeneficiaries(search: 'Rahul', sort: 'amount_desc');

    expect(requested.path, '/beneficiaries');
    expect(requested.queryParameters, {
      'search': 'Rahul',
      'sort': 'amount_desc',
    });
  });
}
