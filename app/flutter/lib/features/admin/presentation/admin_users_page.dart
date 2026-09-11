import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../models/admin_audit_entry.dart';
import '../models/admin_user.dart';
import '../providers/admin_users_providers.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final users = ref.watch(adminUsersProvider);
    final audit = ref.watch(adminAuditHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminManageUsers)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminUsersProvider);
          ref.invalidate(adminAuditHistoryProvider);
          await ref.read(adminUsersProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.adminUsersTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.adminUsersSubtitle),
            const SizedBox(height: 20),
            users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(message: error.toString()),
              data: (items) => _UsersCard(users: items, l10n: l10n, ref: ref),
            ),
            const SizedBox(height: 28),
            Text(l10n.adminAuditHistory, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            audit.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorCard(message: error.toString()),
              data: (items) => _AuditCard(entries: items, l10n: l10n),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersCard extends StatelessWidget {
  const _UsersCard({required this.users, required this.l10n, required this.ref});

  final List<AdminUser> users;
  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.adminNoUsers)));
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < users.length; i++) ...[
            _UserTile(user: users[i], l10n: l10n, ref: ref),
            if (i < users.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.l10n, required this.ref});

  final AdminUser user;
  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null ? const Icon(Icons.person_outline) : null,
      ),
      title: Text(user.label),
      subtitle: Text(user.email ?? l10n.adminNoEmail),
      trailing: user.isAdmin
          ? Chip(label: Text(l10n.adminRole))
          : FilledButton.tonalIcon(
              onPressed: () => _confirmPromotion(context),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: Text(l10n.adminMakeAdmin),
            ),
    );
  }

  Future<void> _confirmPromotion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminMakeAdmin),
        content: Text(l10n.adminMakeAdminConfirmation(user.label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.adminMakeAdmin)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(adminUsersRepositoryProvider).makeAdmin(user.id);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAuditHistoryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminPromotionSuccess)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entries, required this.l10n});

  final List<AdminAuditEntry> entries;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.adminNoAuditHistory)));
    }
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.adminAuditPromotion(entries[i].targetLabel)),
              subtitle: Text(l10n.adminAuditActor(entries[i].actorLabel)),
              trailing: Text(
                MaterialLocalizations.of(context).formatMediumDate(entries[i].createdAt.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (i < entries.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message),
        ),
      );
}
