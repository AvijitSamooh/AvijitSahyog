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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.causesTitle),
      ),
      body: causesAsync.when(
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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: causes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _CauseCard(cause: causes[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause});

  final Cause cause;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          cause.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: cause.description == null || cause.description!.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  cause.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CauseDetailPage(slug: cause.slug),
            ),
          );
        },
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
