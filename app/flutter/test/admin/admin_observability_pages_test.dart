import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/features/admin/data/platform_health_repository.dart';
import 'package:avijit_sahyog/features/admin/models/admin_analytics_summary.dart';
import 'package:avijit_sahyog/features/admin/models/advanced_analytics_summary.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_analytics_page.dart';
import 'package:avijit_sahyog/features/admin/presentation/advanced_analytics_page.dart';
import 'package:avijit_sahyog/features/admin/presentation/platform_health_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_analytics_providers.dart';
import 'package:avijit_sahyog/features/admin/providers/advanced_analytics_providers.dart';
import 'package:avijit_sahyog/features/admin/providers/platform_health_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: AppShellScope(
          onLocaleChanged: (_) {},
          navigation: AppNavigationController(),
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: page,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollPageTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(ListView).first,
    );
  }

  testWidgets('interaction analytics renders metrics and empty trend state', (tester) async {
    const summary = AdminAnalyticsSummary(
      dau: 12,
      wau: 40,
      mau: 100,
      newUsers: 60,
      returningUsers: 40,
      sessions: 180,
      screenViews: 620,
      interactions: 410,
      navigationEvents: 95,
      engagementTrend: [],
    );

    await pumpPage(
      tester,
      const AdminAnalyticsPage(),
      overrides: [
        adminAnalyticsProvider.overrideWith((ref) async => summary),
      ],
    );

    expect(find.text('User engagement'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    await scrollPageTo(tester, find.text('No analytics data yet.'));
    expect(find.text('No analytics data yet.'), findsOneWidget);
    expect(find.text('95'), findsOneWidget);
  });

  testWidgets('advanced analytics renders empty collections', (tester) async {
    const summary = AdvancedAnalyticsSummary(
      retention: [],
      engagementCohorts: [],
      featureAdoption: [],
      segmentation: AnalyticsSegmentation(city: [], language: [], device: []),
      cohortUsers: 0,
      mau: 0,
      bigQueryReady: false,
    );

    await pumpPage(
      tester,
      const AdvancedAnalyticsPage(),
      overrides: [
        advancedAnalyticsProvider.overrideWith((ref) async => summary),
      ],
    );

    expect(find.text('Retention'), findsOneWidget);
    expect(find.text('Engagement cohorts'), findsOneWidget);
    expect(find.text('Feature adoption'), findsOneWidget);
    expect(find.text('Audience segmentation'), findsOneWidget);
    await scrollPageTo(tester, find.text('Warehouse export is not configured.'));
    expect(find.text('Warehouse export is not configured.'), findsOneWidget);
  });

  testWidgets('platform health renders recent events and deployment', (tester) async {
    const summary = PlatformHealthSummary(
      status: 'healthy',
      database: 'healthy',
      api: PlatformHealthApi(status: 'ok', uptimeSeconds: 93784),
      deployment: PlatformDeploymentInfo(
        environment: 'production',
        version: '1.2.3',
        deploymentId: 'deploy-1',
        gitSha: 'abc123',
        deployedAt: null,
      ),
      errors24h: 2,
      authFailures24h: 3,
      uploadFailures24h: 1,
      appErrors24h: 4,
      crashes24h: 0,
      last7Days: {},
      recentEvents: [
        PlatformHealthEvent(
          id: 'event-1',
          type: 'APP_ERROR',
          statusCode: 500,
          route: '/health',
          method: 'GET',
          message: 'database timeout',
          createdAt: '2026-09-13T08:01:00Z',
        ),
      ],
    );

    await pumpPage(
      tester,
      const PlatformHealthPage(),
      overrides: [
        platformHealthProvider.overrideWith((ref) async => summary),
      ],
    );

    expect(find.text('Platform healthy'), findsOneWidget);
    await scrollPageTo(tester, find.text('production'));
    expect(find.text('production'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('database timeout'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('admin analytics exposes retry on load failure', (tester) async {
    await pumpPage(
      tester,
      const AdminAnalyticsPage(),
      overrides: [
        adminAnalyticsProvider.overrideWith((ref) async => throw Exception('failed')),
      ],
    );

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('advanced analytics exposes retry on load failure', (tester) async {
    await pumpPage(
      tester,
      const AdvancedAnalyticsPage(),
      overrides: [
        advancedAnalyticsProvider.overrideWith((ref) async => throw Exception('failed')),
      ],
    );

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('platform health exposes retry on load failure', (tester) async {
    await pumpPage(
      tester,
      const PlatformHealthPage(),
      overrides: [
        platformHealthProvider.overrideWith((ref) async => throw Exception('failed')),
      ],
    );

    expect(find.text('Retry'), findsOneWidget);
  });
}
