import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../models/admin_beneficiary.dart';
import '../providers/admin_beneficiaries_providers.dart';
import 'admin_beneficiary_editor_page.dart';

class AdminBeneficiariesPage extends ConsumerWidget {
  const AdminBeneficiariesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beneficiaries = ref.watch(adminBeneficiariesProvider);
    return AppPageScaffold(
      title: const Text('Manage beneficiaries'),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('admin_create_beneficiary'),
        icon: const Icon(Icons.add),
        label: const Text('Create beneficiary'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminBeneficiaryEditorPage()),
          );
          ref.invalidate(adminBeneficiariesProvider);
        },
      ),
      body: beneficiaries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(adminBeneficiariesProvider),
            child: const Text('Retry loading beneficiaries'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No beneficiaries created yet.'))
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(adminBeneficiariesProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _BeneficiaryTile(beneficiary: items[index]),
                ),
              ),
      ),
    );
  }
}

class _BeneficiaryTile extends ConsumerWidget {
  const _BeneficiaryTile({required this.beneficiary});
  final AdminBeneficiary beneficiary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        key: ValueKey('admin_beneficiary_${beneficiary.id}'),
        title: Text(beneficiary.name),
        subtitle: Text(
          '${beneficiary.supportedYear} • ₹${beneficiary.contributionAmount} • ${beneficiary.isActive ? 'Active' : 'Inactive'}',
        ),
        trailing: Switch(
          value: beneficiary.isActive,
          onChanged: (value) async {
            await ref.read(adminBeneficiariesRepositoryProvider)
                .setActive(beneficiary.id, value);
            ref.invalidate(adminBeneficiariesProvider);
          },
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminBeneficiaryEditorPage(beneficiary: beneficiary),
            ),
          );
          ref.invalidate(adminBeneficiariesProvider);
        },
      ),
    );
  }
}
