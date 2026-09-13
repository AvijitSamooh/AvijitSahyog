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
      appBar: AppBar(
        title: Text(l10n.adminManageUsers),
        actions: [
          IconButton(
            tooltip: l10n.adminMakeAdmin,
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _showPromotionDialog(context, ref, l10n),
          ),
        ],
      ),
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

Future<void> _showPromotionDialog(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) async {
  try {
    final users = await ref.read(adminUsersProvider.future);
    if (!context.mounted) return;
    final candidates = users.where((user) => user.canBePromoted).toList(growable: false);
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminNoUsers)),
      );
      return;
    }

    final selected = await showDialog<AdminUser>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminMakeAdmin),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: candidates.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final user = candidates[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null ? const Icon(Icons.person_outline) : null,
                ),
                title: Text(user.label),
                subtitle: Text(user.email ?? l10n.adminNoEmail),
                onTap: () => Navigator.of(dialogContext).pop(user),
              );
            },
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminMakeAdmin),
        content: Text(l10n.adminMakeAdminConfirmation(selected.label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.adminMakeAdmin)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(adminUsersRepositoryProvider).changeRole(selected.id, 'ADMIN');
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminAuditHistoryProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminPromotionSuccess)),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
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
                      PopupMenuItem(value: 'ADMIN', child: Text(l10n.adminMakeAdmin)),
                    if (user.canBeDemoted)
                      const PopupMenuItem(value: 'USER', child: Text('Remove admin')),
                  ],
                )
              : Chip(label: Text(l10n.adminRole)),
    );
  }

  Future<void> _confirmRoleChange(BuildContext context, String role) async {
    final isPromotion = role == 'ADMIN';
    final action = isPromotion ? l10n.adminMakeAdmin : 'Remove admin';
    final description = isPromotion
        ? l10n.adminMakeAdminConfirmation(user.label)
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
