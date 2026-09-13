import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/admin/data/platform_health_repository.dart';

void main() {
  test('parses a healthy platform summary including recent events', () {
    final summary = PlatformHealthSummary.fromJson({
      'status': 'healthy',
      'database': 'healthy',
      'api': {'status': 'ok', 'uptimeSeconds': 93784},
      'deployment': {
        'environment': 'production',
        'version': '1.2.3',
        'deploymentId': 'deploy-1',
        'gitSha': 'abc123',
        'deployedAt': '2026-09-13T08:00:00Z',
      },
      'errors24h': 2,
      'authFailures24h': 3,
      'uploadFailures24h': 1,
      'appErrors24h': 4,
      'crashes24h': 0,
      'last7Days': {'2026-09-13': 2},
      'recentEvents': [
        {
          'id': 'event-1',
          'type': 'APP_ERROR',
          'statusCode': 500,
          'route': '/health',
          'method': 'GET',
          'message': 'database timeout',
          'createdAt': '2026-09-13T08:01:00Z',
        },
      ],
    });

    expect(summary.status, 'healthy');
    expect(summary.api.uptimeSeconds, 93784);
    expect(summary.deployment.version, '1.2.3');
    expect(summary.last7Days['2026-09-13'], 2);
    expect(summary.recentEvents, hasLength(1));
    expect(summary.recentEvents.single.statusCode, 500);
  });

  test('parses nullable event fields and deployment timestamp', () {
    final summary = PlatformHealthSummary.fromJson({
      'status': 'degraded',
      'database': 'unavailable',
      'api': {'status': 'degraded', 'uptimeSeconds': 0},
      'deployment': {
        'environment': 'unknown',
        'version': 'unknown',
        'deploymentId': 'unknown',
        'gitSha': 'unknown',
        'deployedAt': null,
      },
      'errors24h': 0,
      'authFailures24h': 0,
      'uploadFailures24h': 0,
      'appErrors24h': 0,
      'crashes24h': 0,
      'last7Days': {},
      'recentEvents': [
        {
          'id': 'event-2',
          'type': 'AUTH_FAILURE',
          'statusCode': null,
          'route': null,
          'method': null,
          'message': null,
          'createdAt': '2026-09-13T08:02:00Z',
        },
      ],
    });

    expect(summary.status, 'degraded');
    expect(summary.deployment.deployedAt, isNull);
    expect(summary.recentEvents.single.route, isNull);
    expect(summary.recentEvents.single.message, isNull);
  });
}
