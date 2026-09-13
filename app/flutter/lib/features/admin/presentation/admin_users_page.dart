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
    if (users.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.adminNoUsers),
        ),
      );
    }
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
    final canChange = user.canBePromoted || user.canBeDemoted;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null ? const Icon(Icons.person_outline) : null,
      ),
      title: Text(user.label),
      subtitle: Text(user.email ?? l10n.adminNoEmail),
      trailing: user.isSuperAdmin
          ? const Icon(Icons.shield_rounded)
          : canChange
              ? PopupMenuButton<String>(
                  onSelected: (role) => _confirmRoleChange(context, role),
                  itemBuilder: (context) => [
                    if (user.canBePromoted)
                      const PopupMenuItem(value: 'ADMIN', child: Text('Make admin')),
                    if (user.canBeDemoted)
                      const PopupMenuItem(value: 'USER', child: Text('Remove admin')),
                  ],
                )
              : Chip(label: Text(l10n.adminRole)),
    );
  }

  Future<void> _confirmRoleChange(BuildContext context, String role) async {
    final isPromotion = role == 'ADMIN';
    final action = isPromotion ? 'Make admin' : 'Remove admin';
    final description = isPromotion
        ? 'Make ${user.label} an administrator? This action will be recorded in audit history.'
        : 'Remove administrator access from ${user.label}? This action will be recorded in audit history.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text(description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(adminUsersRepositoryProvider).changeRole(user.id, role);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAuditHistoryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPromotion ? l10n.adminPromotionSuccess : 'Administrator access removed and the change was recorded.')),
        );
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
              title: Text(_auditTitle(entries[i])),
              subtitle: Text('${l10n.adminAuditActor(entries[i].actorLabel)} · ${entries[i].fromRole ?? '—'} → ${entries[i].toRole ?? '—'}'),
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

  String _auditTitle(AdminAuditEntry entry) {
    if (entry.fromRole == 'ADMIN' && entry.toRole == 'USER') {
      return 'Administrator access removed from ${entry.targetLabel}';
    }
    return l10n.adminAuditPromotion(entry.targetLabel);
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
