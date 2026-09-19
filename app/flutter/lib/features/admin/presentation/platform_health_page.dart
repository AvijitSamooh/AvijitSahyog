import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_settings_menu.dart';
import '../data/platform_health_repository.dart';
import '../providers/platform_health_providers.dart';

class PlatformHealthPage extends ConsumerWidget {
  const PlatformHealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(platformHealthProvider);
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: Text(l10n.adminPlatformHealthTitle),
      body: health.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(platformHealthProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformHealthProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatusCard(summary: data),
              const SizedBox(height: 16),
              Text(l10n.adminLast24Hours, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _MetricGrid(metrics: [
                _Metric('API errors', data.errors24h, Icons.error_outline_rounded),
                _Metric('Auth failures', data.authFailures24h, Icons.lock_outline_rounded),
                _Metric('Upload failures', data.uploadFailures24h, Icons.cloud_upload_outlined),
                _Metric('App errors', data.appErrors24h, Icons.bug_report_outlined),
                _Metric('Crashes', data.crashes24h, Icons.warning_amber_rounded),
              ]),
              const SizedBox(height: 20),
              _DeploymentCard(info: data.deployment),
              const SizedBox(height: 20),
              Text(l10n.adminRecentEvents, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (data.recentEvents.isEmpty)
                Card(child: ListTile(title: Text(l10n.adminNoHealthEvents)))
              else
                ...data.recentEvents.map((event) => Card(
                  child: ListTile(
                    leading: Icon(_iconFor(event.type)),
                    title: Text(event.type.replaceAll('_', ' ')),
                    subtitle: Text([if (event.method != null) event.method!, if (event.route != null) event.route!, if (event.message != null) event.message!].join(' · ')),
                    trailing: event.statusCode == null ? null : Text('${event.statusCode}'),
                  ),
                )),
              const SizedBox(height: 12),
              Text(l10n.adminHealthTelemetryPrivacy, style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'AUTH_FAILURE': return Icons.lock_outline_rounded;
      case 'UPLOAD_FAILURE': return Icons.cloud_upload_outlined;
      case 'APP_CRASH': return Icons.warning_amber_rounded;
      case 'APP_ERROR': return Icons.bug_report_outlined;
      default: return Icons.error_outline_rounded;
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.summary});
  final PlatformHealthSummary summary;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(summary.status == 'healthy' ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, size: 34), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(summary.status == 'healthy' ? l10n.adminPlatformHealthy : l10n.adminPlatformDegraded, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 4), Text(l10n.adminApiDatabaseUptime(summary.api.status, summary.database, _formatUptime(summary.api.uptimeSeconds)))]))])));
}

class _Metric { const _Metric(this.label, this.value, this.icon); final String label; final int value; final IconData icon; }
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics}); final List<_Metric> metrics;
  @override Widget build(BuildContext context) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: metrics.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55), itemBuilder: (context, index) { final metric = metrics[index]; return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(metric.icon, size: 22), Text(metric.label), Text('${metric.value}', style: Theme.of(context).textTheme.headlineSmall)]))); });
}

class _DeploymentCard extends StatelessWidget {
  const _DeploymentCard({required this.info}); final PlatformDeploymentInfo info;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l10n.adminDeployment, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 10), _row(l10n.adminEnvironment, info.environment), _row(l10n.adminVersion, info.version), _row(l10n.adminDeploymentId, info.deploymentId), _row(l10n.adminGitSha, info.gitSha), if (info.deployedAt != null) _row(l10n.adminDeployedAt, info.deployedAt!)])));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [SizedBox(width: 110, child: Text(label)), Expanded(child: Text(value, overflow: TextOverflow.ellipsis))]));
}

String _formatUptime(int seconds) { final days = seconds ~/ 86400; final hours = (seconds % 86400) ~/ 3600; final minutes = (seconds % 3600) ~/ 60; return '${days}d ${hours}h ${minutes}m'; }
