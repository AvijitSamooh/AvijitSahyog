import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../models/cause.dart';
import '../providers/causes_providers.dart';
import 'cause_detail_page.dart';

class CausesPage extends ConsumerWidget {
  const CausesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final causesAsync = ref.watch(causesProvider(languageCode));
    final l10n = AppLocalizations.of(context)!;

    return causesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: l10n.causesLoadError,
          onRetry: () => ref.invalidate(causesProvider(languageCode)),
        ),
        data: (causes) {
          if (causes.isEmpty) {
            return Center(child: Text(l10n.noCauses));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(causesProvider(languageCode));
              await ref.read(causesProvider(languageCode).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  l10n.welcomeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ...causes.map(
                  (cause) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CauseCard(cause: cause),
                  ),
                ),
              ],
            ),
          );
        },
      );
  }
}

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause});

  final Cause cause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cause.children.isEmpty) {
      return _LeafCauseCard(cause: cause);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('cause_parent_${cause.id}'),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFCE8C9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.account_tree_rounded,
            color: Color(0xFF6E1A14),
            size: 27,
          ),
        ),
        title: Text(cause.name, style: theme.textTheme.titleMedium),
        subtitle: cause.description?.isNotEmpty == true
            ? Text(cause.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        children: [
          for (final child in cause.children)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _ChildCauseTile(cause: child),
            ),
        ],
      ),
    );
  }
}

class _LeafCauseCard extends StatelessWidget {
  const _LeafCauseCard({required this.cause});

  final Cause cause;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: _ChildCauseTile(cause: cause, padding: const EdgeInsets.all(18)),
    );
  }
}

class _ChildCauseTile extends StatelessWidget {
  const _ChildCauseTile({required this.cause, this.padding});

  final Cause cause;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('cause_child_${cause.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CauseDetailPage(slug: cause.slug),
          ),
        );
      },
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.subdirectory_arrow_right_rounded, color: Color(0xFF9A574C)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cause.name, style: theme.textTheme.titleSmall),
                  if (cause.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      cause.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9A574C)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFF6E1A14),
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}
