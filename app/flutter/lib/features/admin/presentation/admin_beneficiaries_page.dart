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
        error: (error, stackTrace) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(adminBeneficiariesProvider),
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
        leading: Icon(
          beneficiary.isActive
              ? Icons.check_circle_rounded
              : Icons.pause_circle_rounded,
        ),
        title: Text(beneficiary.name),
        subtitle: Text(
          '${beneficiary.supportedYear} • ₹${beneficiary.contributionAmount} • ${beneficiary.isActive ? 'Active' : 'Inactive'}',
        ),
        trailing: Switch(
          key: ValueKey('admin_beneficiary_active_${beneficiary.id}'),
          value: beneficiary.isActive,
          onChanged: (value) async {
            try {
              await ref
                  .read(adminBeneficiariesRepositoryProvider)
                  .setActive(beneficiary.id, value);
              ref.invalidate(adminBeneficiariesProvider);
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unable to update beneficiary status: $error')),
                );
              }
            }
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('Unable to load beneficiaries.'),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
