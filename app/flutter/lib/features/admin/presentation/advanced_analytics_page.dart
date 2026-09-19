import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../models/advanced_analytics_summary.dart';
import '../providers/advanced_analytics_providers.dart';

class AdvancedAnalyticsPage extends ConsumerWidget {
  const AdvancedAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(advancedAnalyticsProvider);
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: Text(l10n.adminAdvancedAnalyticsTitle),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(advancedAnalyticsProvider),
            child: Text(l10n.retry),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(advancedAnalyticsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Section(title: l10n.adminRetention, subtitle: l10n.adminRetentionSubtitle),
              _RetentionTable(data.retention),
              const SizedBox(height: 20),
              _Section(title: l10n.adminEngagementCohorts, subtitle: l10n.adminEngagementCohortsSubtitle),
              _EngagementTable(data.engagementCohorts),
              const SizedBox(height: 20),
              _Section(title: l10n.adminFeatureAdoption, subtitle: l10n.adminFeatureAdoptionSubtitle),
              _FeatureList(data.featureAdoption),
              const SizedBox(height: 20),
              _Section(title: l10n.adminAudienceSegmentation, subtitle: l10n.adminAudienceSegmentationSubtitle),
              _SegmentCard(title: l10n.adminCity, segments: data.segmentation.city),
              _SegmentCard(title: l10n.adminLanguage, segments: data.segmentation.language),
              _SegmentCard(title: l10n.adminDevice, segments: data.segmentation.device),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storage_rounded),
                  title: Text(l10n.adminBigQueryFoundation),
                  subtitle: Text(
                    data.bigQueryReady
                        ? l10n.adminBigQueryReady
                        : l10n.adminWarehouseNotConfigured,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.adminCityPrivacy, style: const TextStyle(fontSize: 12)),
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
              DataColumn(label: Text(l10n.adminCohort)),
              DataColumn(label: Text(l10n.adminUsers)),
              DataColumn(label: Text(l10n.adminDay1)),
              DataColumn(label: Text(l10n.adminDay7)),
              DataColumn(label: Text(l10n.adminDay30)),
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
              DataColumn(label: Text(AppLocalizations.of(context)!.adminCohort)),
              DataColumn(label: Text(AppLocalizations.of(context)!.adminUsers)),
              DataColumn(label: Text(l10n.adminSessions)),
              DataColumn(label: Text(l10n.adminInteractions)),
              DataColumn(label: Text(l10n.adminSessionsPerUser)),
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
                  subtitle: Text(AppLocalizations.of(context)!.adminUserViews(row.users, row.events)),
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
                  subtitle: Text(AppLocalizations.of(context)!.adminUserEvents(row.users, row.events)),
                  trailing: Text('${row.sharePercent}%'),
                ),
              )
              .toList(),
        ),
      );
}
