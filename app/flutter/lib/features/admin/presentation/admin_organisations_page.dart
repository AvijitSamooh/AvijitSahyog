import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../../../l10n/app_localizations.dart';
import '../models/admin_organisation.dart';
import '../providers/admin_organisations_providers.dart';
import 'admin_organisation_editor_page.dart';

class AdminOrganisationsPage extends ConsumerWidget {
  const AdminOrganisationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final organisations = ref.watch(adminOrganisationsProvider);
    return AppPageScaffold(
      title: Text(l10n.adminManageOrganisations),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('admin_create_organisation'),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminCreateOrganisation),
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
            child: Text(l10n.adminRetryLoadingOrganisations),
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.adminNoOrganisations))
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
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        key: ValueKey('admin_organisation_${organisation.id}'),
        title: Text(organisation.displayName(languageCode)),
        subtitle: Text(
          '${organisation.slug} • ${l10n.adminOrganisationCauseCount(organisation.causeIds.length)}',
        ),
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
              tooltip: l10n.adminOrganisationActions,
              onSelected: (action) {
                if (action == 'delete') {
                  _deleteOrganisation(context, ref);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(l10n.adminDeleteOrganisation),
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
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final organisationName = organisation.displayName(languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminDeleteOrganisationTitle),
        content: Text(
          l10n.adminDeleteOrganisationConfirmation(organisationName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.adminDeleteOrganisation),
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
          SnackBar(
            content: Text(
              l10n.adminDeleteOrganisationSuccess(organisationName),
            ),
          ),
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
