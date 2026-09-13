import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../models/admin_organisation.dart';
import '../providers/admin_organisations_providers.dart';
import 'admin_organisation_editor_page.dart';

class AdminOrganisationsPage extends ConsumerWidget {
  const AdminOrganisationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organisations = ref.watch(adminOrganisationsProvider);
    return AppPageScaffold(
      title: const Text('Manage organisations'),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('admin_create_organisation'),
        icon: const Icon(Icons.add),
        label: const Text('Create organisation'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdminOrganisationEditorPage(),
            ),
          );
          ref.invalidate(adminOrganisationsProvider);
        },
      ),
      body: organisations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(adminOrganisationsProvider),
            child: const Text('Retry loading organisations'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No organisations created yet.'))
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(adminOrganisationsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _OrganisationTile(organisation: items[index]),
                ),
              ),
      ),
    );
  }
}

class _OrganisationTile extends ConsumerWidget {
  const _OrganisationTile({required this.organisation});
  final AdminOrganisation organisation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        key: ValueKey('admin_organisation_${organisation.id}'),
        title: Text(organisation.displayName),
        subtitle: Text('${organisation.slug} • ${organisation.causeIds.length} causes'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: organisation.isActive,
              onChanged: (value) async {
                try {
                  await ref
                      .read(adminOrganisationsRepositoryProvider)
                      .setActive(organisation.id, value);
                  ref.invalidate(adminOrganisationsProvider);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                }
              },
            ),
            PopupMenuButton<String>(
              tooltip: 'Organisation actions',
              onSelected: (action) {
                if (action == 'delete') {
                  _deleteOrganisation(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete organisation'),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AdminOrganisationEditorPage(organisation: organisation),
            ),
          );
          ref.invalidate(adminOrganisationsProvider);
        },
      ),
    );
  }

  Future<void> _deleteOrganisation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete organisation?'),
        content: Text(
          'Delete “${organisation.displayName}” permanently? This cannot be undone. If it has donation allocations or beneficiary records, deletion will be blocked and the organisation must be deactivated instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(adminOrganisationsRepositoryProvider)
          .delete(organisation.id);
      ref.invalidate(adminOrganisationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('“${organisation.displayName}” was deleted.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}
