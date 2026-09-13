import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../models/advanced_analytics_summary.dart';
import '../providers/advanced_analytics_providers.dart';

class AdvancedAnalyticsPage extends ConsumerWidget {
  const AdvancedAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(advancedAnalyticsProvider);
    return AppPageScaffold(
      title: const Text('Advanced analytics'),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(advancedAnalyticsProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(advancedAnalyticsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _Section(
                title: 'Retention',
                subtitle: 'Weekly cohorts with Day 1, Day 7 and Day 30 return rates.',
              ),
              _RetentionTable(data.retention),
              const SizedBox(height: 20),
              const _Section(
                title: 'Engagement cohorts',
                subtitle: 'Weekly active cohorts, sessions and interaction depth.',
              ),
              _EngagementTable(data.engagementCohorts),
              const SizedBox(height: 20),
              const _Section(
                title: 'Feature adoption',
                subtitle: 'Share of 30-day active users who viewed each tracked screen.',
              ),
              _FeatureList(data.featureAdoption),
              const SizedBox(height: 20),
              const _Section(
                title: 'Audience segmentation',
                subtitle: 'Thirty-day active users by available city, language and device context.',
              ),
              _SegmentCard(title: 'City', segments: data.segmentation.city),
              _SegmentCard(title: 'Language', segments: data.segmentation.language),
              _SegmentCard(title: 'Device', segments: data.segmentation.device),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storage_rounded),
                  title: const Text('BigQuery-ready foundation'),
                  subtitle: Text(
                    data.bigQueryReady
                        ? 'Event-level PostgreSQL data is shaped for a future BigQuery export.'
                        : 'Warehouse export is not configured.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'City is shown when the client supplies an analytics city context; the app does not infer precise location.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      );
}

class _RetentionTable extends StatelessWidget {
  const _RetentionTable(this.rows);

  final List<RetentionCohort> rows;

  @override
  Widget build(BuildContext context) => Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Cohort')),
              DataColumn(label: Text('Users')),
              DataColumn(label: Text('D1')),
              DataColumn(label: Text('D7')),
              DataColumn(label: Text('D30')),
            ],
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: [
                      DataCell(Text(row.cohort)),
                      DataCell(Text('${row.users}')),
                      DataCell(Text('${row.day1Percent}%')),
                      DataCell(Text('${row.day7Percent}%')),
                      DataCell(Text('${row.day30Percent}%')),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      );
}

class _EngagementTable extends StatelessWidget {
  const _EngagementTable(this.rows);

  final List<EngagementCohort> rows;

  @override
  Widget build(BuildContext context) => Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Cohort')),
              DataColumn(label: Text('Users')),
              DataColumn(label: Text('Sessions')),
              DataColumn(label: Text('Interactions')),
              DataColumn(label: Text('Sessions/user')),
            ],
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: [
                      DataCell(Text(row.cohort)),
                      DataCell(Text('${row.users}')),
                      DataCell(Text('${row.sessions}')),
                      DataCell(Text('${row.interactions}')),
                      DataCell(Text('${row.sessionsPerUser}')),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      );
}

class _FeatureList extends StatelessWidget {
  const _FeatureList(this.rows);

  final List<FeatureAdoption> rows;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          children: rows
              .take(15)
              .map(
                (row) => ListTile(
                  title: Text(row.feature),
                  subtitle: Text('${row.users} users · ${row.events} views'),
                  trailing: Text('${row.adoptionPercent}%'),
                ),
              )
              .toList(),
        ),
      );
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({required this.title, required this.segments});

  final String title;
  final List<AnalyticsSegment> segments;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ExpansionTile(
          title: Text(title),
          children: segments
              .take(15)
              .map(
                (row) => ListTile(
                  title: Text(row.segment),
                  subtitle: Text('${row.users} users · ${row.events} events'),
                  trailing: Text('${row.sharePercent}%'),
                ),
              )
              .toList(),
        ),
      );
}
