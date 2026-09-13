import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/admin/models/advanced_analytics_summary.dart';

void main() {
  test('parses retention, engagement, adoption and segmentation data', () {
    final summary = AdvancedAnalyticsSummary.fromJson({
      'retention': [
        {
          'cohort': '2026-W36',
          'users': 100,
          'day1Percent': 42.5,
          'day7Percent': 18,
          'day30Percent': 9.5,
        },
      ],
      'engagementCohorts': [
        {
          'cohort': '2026-09-01',
          'users': 50,
          'sessions': 125,
          'interactions': 400,
          'sessionsPerUser': 2.5,
        },
      ],
      'featureAdoption': [
        {
          'feature': 'causes',
          'users': 80,
          'events': 220,
          'adoptionPercent': 64,
        },
      ],
      'segmentation': {
        'city': [
          {'segment': 'Pune', 'users': 40, 'events': 100, 'sharePercent': 50},
        ],
        'language': [
          {'segment': 'en', 'users': 30, 'events': 70, 'sharePercent': 60},
        ],
        'device': [
          {'segment': 'android', 'users': 45, 'events': 120, 'sharePercent': 90},
        ],
      },
      'cohortUsers': 100,
      'mau': 125,
      'warehouse': {'bigQueryReady': true},
    });

    expect(summary.retention.single.day7Percent, 18);
    expect(summary.engagementCohorts.single.sessions, 125);
    expect(summary.featureAdoption.single.adoptionPercent, 64);
    expect(summary.segmentation.city.single.segment, 'Pune');
    expect(summary.segmentation.language.single.sharePercent, 60);
    expect(summary.segmentation.device.single.users, 45);
    expect(summary.cohortUsers, 100);
    expect(summary.mau, 125);
    expect(summary.bigQueryReady, isTrue);
  });

  test('preserves empty analytics collections', () {
    final summary = AdvancedAnalyticsSummary.fromJson({
      'retention': [],
      'engagementCohorts': [],
      'featureAdoption': [],
      'segmentation': {'city': [], 'language': [], 'device': []},
      'cohortUsers': 0,
      'mau': 0,
      'warehouse': {'bigQueryReady': false},
    });

    expect(summary.retention, isEmpty);
    expect(summary.engagementCohorts, isEmpty);
    expect(summary.featureAdoption, isEmpty);
    expect(summary.segmentation.city, isEmpty);
    expect(summary.bigQueryReady, isFalse);
  });
}
