import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../../../l10n/app_localizations.dart';
import '../models/admin_dashboard_summary.dart';
import '../providers/admin_dashboard_providers.dart';
import 'admin_beneficiaries_page.dart';
import 'admin_causes_page.dart';
import 'admin_organisations_page.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(adminDashboardProvider);
    return AppPageScaffold(
      title: Text(l10n.adminDashboard),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(adminDashboardProvider),
            child: Text(l10n.retry),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.adminDashboardOverview, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _MetricCard(title: l10n.adminManageCauses, activeLabel: l10n.adminActive, inactiveLabel: l10n.adminInactive, metric: data.causes, icon: Icons.volunteer_activism_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCausesPage()))),
            _MetricCard(title: l10n.adminManageOrganisations, activeLabel: l10n.adminActive, inactiveLabel: l10n.adminInactive, metric: data.organisations, icon: Icons.business_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminOrganisationsPage()))),
            _MetricCard(title: l10n.adminManageBeneficiaries, activeLabel: l10n.adminActive, inactiveLabel: l10n.adminInactive, metric: data.beneficiaries, icon: Icons.auto_awesome_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminBeneficiariesPage()))),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.activeLabel, required this.inactiveLabel, required this.metric, required this.icon, required this.onTap});
  final String title;
  final String activeLabel;
  final String inactiveLabel;
  final AdminDashboardMetric metric;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text('Active: ${metric.active} • Inactive: ${metric.inactive}'),
      trailing: Text('${metric.total}', style: Theme.of(context).textTheme.headlineSmall),
      onTap: onTap,
    ),
  );
}
