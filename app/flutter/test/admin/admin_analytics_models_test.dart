import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/admin/models/admin_analytics_summary.dart';

void main() {
  test('parses dashboard metrics and engagement trend', () {
    final summary = AdminAnalyticsSummary.fromJson({
      'dau': 12,
      'wau': 40,
      'mau': 100,
      'newUsers': 60,
      'returningUsers': 40,
      'sessions': 180,
      'screenViews': 620,
      'interactions': 410,
      'navigationEvents': 95,
      'engagementTrend': [
        {
          'date': '2026-09-13',
          'activeUsers': 12,
          'sessions': 25,
          'screenViews': 80,
          'interactions': 55,
        },
      ],
    });

    expect(summary.dau, 12);
    expect(summary.wau, 40);
    expect(summary.mau, 100);
    expect(summary.newUsers, 60);
    expect(summary.returningUsers, 40);
    expect(summary.sessions, 180);
    expect(summary.screenViews, 620);
    expect(summary.interactions, 410);
    expect(summary.navigationEvents, 95);
    expect(summary.engagementTrend.single.activeUsers, 12);
    expect(summary.engagementTrend.single.screenViews, 80);
  });

  test('supports an empty engagement trend', () {
    final summary = AdminAnalyticsSummary.fromJson({
      'dau': 0,
      'wau': 0,
      'mau': 0,
      'newUsers': 0,
      'returningUsers': 0,
      'sessions': 0,
      'screenViews': 0,
      'interactions': 0,
      'navigationEvents': 0,
      'engagementTrend': [],
    });

    expect(summary.engagementTrend, isEmpty);
  });
}
