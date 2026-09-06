import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_settings_menu.dart';
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

    return AppPageScaffold(
      title: Text(l10n.causesTitle),
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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  l10n.causesTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
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
      ),
    );
  }
}

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause});

  final Cause cause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CauseDetailPage(slug: cause.slug),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8C9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFF6E1A14),
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cause.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (cause.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
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
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF9A574C),
                ),
              ),
            ],
          ),
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
