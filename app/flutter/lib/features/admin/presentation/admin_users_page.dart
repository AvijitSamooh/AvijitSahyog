import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_users_repository.dart';
import '../models/admin_audit_entry.dart';
import '../models/admin_user.dart';
import '../models/paginated_admin_users.dart';
import '../providers/admin_users_providers.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  int _page = 1;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim();
        _page = 1;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _search = '';
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final users = ref.watch(adminUsersProvider((
      search: _search.isEmpty ? null : _search,
      page: _page,
      role: 'ADMIN',
    )));
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
          await ref.read(adminUsersProvider((
            search: _search.isEmpty ? null : _search,
            page: _page,
            role: 'ADMIN',
          )).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.adminUsersTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.adminUsersSubtitle),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.impactSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            users.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _ErrorCard(message: error.toString()),
              data: (result) => _UsersSection(
                result: result,
                l10n: l10n,
                ref: ref,
                onPrevious: result.hasPreviousPage ? () => setState(() => _page--) : null,
                onNext: result.hasNextPage ? () => setState(() => _page++) : null,
                onSearchUsers: _search.isEmpty
                    ? null
                    : () => _showPromotionDialog(
                          context,
                          ref,
                          l10n,
                          initialSearch: _search,
                        ),
              ),
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
  AppLocalizations l10n, {
  String? initialSearch,
}) async {
  final selected = await showDialog<AdminUser>(
    context: context,
    builder: (_) => _PromotionDialog(
      initialSearch: initialSearch,
      repository: ref.read(adminUsersRepositoryProvider),
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

  try {
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

class _PromotionDialog extends StatefulWidget {
  const _PromotionDialog({this.initialSearch, required this.repository});

  final String? initialSearch;
  final AdminUsersRepository repository;

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  static const _pageSize = 10;
  final _searchController = TextEditingController();
  Timer? _debounce;
  PaginatedAdminUsers? _result;
  bool _loading = true;
  String _search = '';
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initialSearch = widget.initialSearch?.trim() ?? '';
    _search = initialSearch;
    _searchController.text = initialSearch;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.getUsers(
        search: _search.isEmpty ? null : _search,
        role: 'USER',
        page: _page,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim();
        _page = 1;
      });
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = _result;

    return AlertDialog(
      title: Text(l10n.adminMakeAdmin),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.impactSearch,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorCard(message: _error!)
                      : result == null || result.items.isEmpty
                          ? Center(child: Text(l10n.adminNoUsers))
                          : ListView.separated(
                              itemCount: result.items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final user = result.items[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                                    child: user.photoUrl == null ? const Icon(Icons.person_outline) : null,
                                  ),
                                  title: Text(user.label),
                                  subtitle: Text(user.email ?? l10n.adminNoEmail),
                                  onTap: () => Navigator.of(context).pop(user),
                                );
                              },
                            ),
            ),
            if (result != null && result.totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                    onPressed: result.hasPreviousPage
                        ? () {
                            setState(() => _page--);
                            _load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${result.page} / ${result.totalPages}'),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                    onPressed: result.hasNextPage
                        ? () {
                            setState(() => _page++);
                            _load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({
    required this.result,
    required this.l10n,
    required this.ref,
    required this.onPrevious,
    required this.onNext,
    required this.onSearchUsers,
  });

  final PaginatedAdminUsers result;
  final AppLocalizations l10n;
  final WidgetRef ref;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSearchUsers;

  @override
  Widget build(BuildContext context) {
    if (result.items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminNoUsers),
              if (onSearchUsers != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onSearchUsers,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.adminMakeAdmin),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Card(
          child: Column(
            children: [
              for (var i = 0; i < result.items.length; i++) ...[
                _UserTile(user: result.items[i], l10n: l10n, ref: ref),
                if (i < result.items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
        if (result.totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${result.page} / ${result.totalPages}'),
              IconButton(
                tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
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
    final canChange = user.canBeDemoted;
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
                    PopupMenuItem(value: 'USER', child: Text(l10n.adminRemoveAdmin)),
                  ],
                )
              : Chip(label: Text(l10n.adminRole)),
    );
  }

  Future<void> _confirmRoleChange(BuildContext context, String role) async {
    final description = l10n.adminRemoveAdminConfirmation(user.label);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminRemoveAdmin),
        content: Text(description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.adminRemoveAdmin)),
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
          SnackBar(content: Text(l10n.adminDemotionSuccess)),
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
      return l10n.adminAuditDemotion(entry.targetLabel);
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
