import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_analytics_providers.dart';

class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(adminAnalyticsProvider);
    return AppPageScaffold(
      title: const Text('Interaction analytics'),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(adminAnalyticsProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminAnalyticsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'User engagement',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text('Rolling 30-day metrics with a 14-day engagement trend.'),
              const SizedBox(height: 18),
              _MetricGrid(metrics: [
                _Metric('DAU', data.dau, Icons.today_rounded),
                _Metric('WAU', data.wau, Icons.date_range_rounded),
                _Metric('MAU', data.mau, Icons.calendar_month_rounded),
                _Metric('New users', data.newUsers, Icons.person_add_alt_rounded),
                _Metric('Returning', data.returningUsers, Icons.replay_rounded),
                _Metric('Sessions', data.sessions, Icons.timer_rounded),
                _Metric('Screen views', data.screenViews, Icons.visibility_rounded),
                _Metric('Interactions', data.interactions, Icons.touch_app_rounded),
              ]),
              const SizedBox(height: 20),
              _TrendCard(points: data.engagementTrend),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.navigation_rounded),
                  title: const Text('Navigation events'),
                  subtitle: const Text('Included in interaction totals.'),
                  trailing: Text(
                    '${data.navigationEvents}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Analytics use opaque app-generated identifiers and do not display personal identifiers.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(metric.icon, size: 22),
                Text(metric.label, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${metric.value}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});
  final List<dynamic> points;

  @override
  Widget build(BuildContext context) {
    final values = points.map((point) => (point.activeUsers as int)).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Engagement trend', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Daily active users · last 14 days'),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: values.isEmpty
                  ? const Center(child: Text('No analytics data yet.'))
                  : CustomPaint(
                      painter: _TrendPainter(values),
                      child: const SizedBox.expand(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.values);
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    final denominator = maxValue == 0 ? 1 : maxValue;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : size.width * i / (values.length - 1);
      final y = size.height - (values[i] / denominator) * (size.height - 12) - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.values != values;
}
