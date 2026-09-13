import 'package:flutter/material.dart';
import '../../../core/navigation/app_shell_scope.dart';
import '../../../core/widgets/app_navigation_bar.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../../../l10n/app_localizations.dart';
import 'admin_dashboard_page.dart';
import 'admin_beneficiaries_page.dart';
import 'admin_causes_page.dart';
import 'admin_organisations_page.dart';
import 'admin_users_page.dart';

class AdminPortalPage extends StatelessWidget {
  const AdminPortalPage({super.key});

  void _selectMainTab(BuildContext context, int index) {
    final shell = AppShellScope.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    shell.navigation.select(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shell = AppShellScope.of(context);

    return AnimatedBuilder(
      animation: shell.navigation,
      builder: (context, _) => AppPageScaffold(
        title: Text(l10n.adminPortal),
        bottomNavigationBar: AppNavigationBar(
          selectedIndex: shell.navigation.index,
          onDestinationSelected: (index) => _selectMainTab(context, index),
        ),
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
              icon: Icons.dashboard_rounded,
              title: l10n.adminDashboard,
              subtitle: l10n.adminDashboardSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
              ),
            ),
            const SizedBox(height: 12),
            _AdminSectionCard(
              icon: Icons.people_alt_rounded,
              title: l10n.adminManageUsers,
              subtitle: l10n.adminManageUsersSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminUsersPage()),
              ),
            ),
            const SizedBox(height: 12),
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminOrganisationsPage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _AdminSectionCard(
              icon: Icons.auto_awesome_rounded,
              title: l10n.adminManageBeneficiaries,
              subtitle: l10n.adminManageBeneficiariesSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminBeneficiariesPage(),
                ),
              ),
            ),
          ],
        ),
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
