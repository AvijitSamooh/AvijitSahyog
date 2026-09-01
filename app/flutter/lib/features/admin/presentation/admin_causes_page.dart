import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_cause.dart';
import '../providers/admin_causes_providers.dart';
import 'admin_cause_editor_page.dart';

class AdminCausesPage extends ConsumerWidget {
  const AdminCausesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final causes = ref.watch(adminCausesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage causes')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('admin_create_cause'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminCauseEditorPage()),
          );
          ref.invalidate(adminCausesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Create cause'),
      ),
      body: causes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(adminCausesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No causes created yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminCausesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) => _CauseTile(cause: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _CauseTile extends ConsumerWidget {
  const _CauseTile({required this.cause});

  final AdminCause cause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        key: ValueKey('admin_cause_${cause.id}'),
        title: Text(cause.displayName),
        subtitle: Text('${cause.slug} • Order ${cause.displayOrder}'),
        leading: Icon(
          cause.isActive ? Icons.check_circle_rounded : Icons.pause_circle,
        ),
        trailing: Switch(
          key: ValueKey('admin_cause_active_${cause.id}'),
          value: cause.isActive,
          onChanged: (value) async {
            try {
              await ref
                  .read(adminCausesRepositoryProvider)
                  .setActive(cause.id, value);
              ref.invalidate(adminCausesProvider);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to update cause status.')),
                );
              }
            }
          },
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminCauseEditorPage(cause: cause),
            ),
          );
          ref.invalidate(adminCausesProvider);
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
            const Text('Unable to load causes.'),
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
