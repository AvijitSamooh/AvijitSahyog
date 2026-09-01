import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_organisation.dart';
import '../providers/admin_organisations_providers.dart';
import 'admin_organisation_editor_page.dart';

class AdminOrganisationsPage extends ConsumerWidget {
  const AdminOrganisationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organisations = ref.watch(adminOrganisationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage organisations')),
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
        trailing: Switch(
          value: organisation.isActive,
          onChanged: (value) async {
            await ref
                .read(adminOrganisationsRepositoryProvider)
                .setActive(organisation.id, value);
            ref.invalidate(adminOrganisationsProvider);
          },
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
}
