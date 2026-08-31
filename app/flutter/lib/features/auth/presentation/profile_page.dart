import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: user == null
          ? Center(child: Text(l10n.loginRequired))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl == null
                        ? null
                        : NetworkImage(user.photoUrl!),
                    child: user.photoUrl == null
                        ? const Icon(Icons.person_rounded)
                        : null,
                  ),
                  title: Text(user.displayName ?? l10n.profile),
                  subtitle: Text(user.email ?? ''),
                ),
                const Divider(),
                if (user.isAdmin)
                  ListTile(
                    key: const ValueKey('admin_portal_entry'),
                    leading: const Icon(Icons.admin_panel_settings_rounded),
                    title: Text(l10n.adminPortal),
                    subtitle: Text(l10n.adminPortalSubtitle),
                    onTap: () {},
                  ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(l10n.logout),
                  onTap: () => ref.read(authProvider.notifier).signOut(),
                ),
              ],
            ),
    );
  }
}
