import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../models/admin_cause.dart';
import '../providers/admin_causes_providers.dart';
import 'admin_cause_editor_page.dart';

class AdminCausesPage extends ConsumerWidget {
  const AdminCausesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final causes = ref.watch(adminCausesProvider);

    return AppPageScaffold(
      title: const Text('Manage causes'),
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

          final roots = items.where((item) => item.parentId == null).toList(growable: false);
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminCausesProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final cause in roots) ...[
                  _CauseTile(cause: cause),
                  for (final child in cause.children)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, top: 6),
                      child: _CauseTile(cause: child, child: true),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CauseTile extends ConsumerWidget {
  const _CauseTile({required this.cause, this.child = false});

  final AdminCause cause;
  final bool child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Card(
      child: ListTile(
        key: ValueKey('admin_cause_${cause.id}'),
        contentPadding: EdgeInsets.only(left: child ? 12 : 16, right: 8),
        title: Row(
          children: [
            if (child) ...[
              const Icon(Icons.subdirectory_arrow_right_rounded, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(cause.displayName(languageCode))),
          ],
        ),
        subtitle: Text(
          child ? cause.slug : '${cause.slug} • Order ${cause.displayOrder}',
        ),
        leading: Icon(
          child
              ? Icons.label_outline_rounded
              : (cause.children.isNotEmpty
                  ? Icons.account_tree_rounded
                  : Icons.check_circle_rounded),
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
