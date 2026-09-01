import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'admin_causes_page.dart';
import 'admin_organisations_page.dart';

class AdminPortalPage extends StatelessWidget {
  const AdminPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPortal)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.adminPortalWelcome,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(l10n.adminPortalDescription),
          const SizedBox(height: 24),
          _AdminSectionCard(
            icon: Icons.volunteer_activism_rounded,
            title: l10n.adminManageCauses,
            subtitle: l10n.adminManageCausesSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminCausesPage()),
            ),
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.business_rounded,
            title: l10n.adminManageOrganisations,
            subtitle: l10n.adminManageOrganisationsSubtitle,
            onTap: null,
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.auto_awesome_rounded,
            title: l10n.adminManageBeneficiaries,
            subtitle: l10n.adminManageBeneficiariesSubtitle,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
