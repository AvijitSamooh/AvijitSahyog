import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../models/organisation.dart';
import '../providers/causes_providers.dart';

class CauseDetailPage extends ConsumerWidget {
  const CauseDetailPage({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final causeAsync = ref.watch(
      causeProvider((slug: slug, languageCode: languageCode)),
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(),
      body: causeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.causeLoadError,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (cause) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              cause.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (cause.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(cause.description!),
            ],
            if (cause.organisations.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                l10n.affiliatedOrganisations,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...cause.organisations.map(
                (organisation) => Card(
                  child: ListTile(
                    title: Text(organisation.name),
                    subtitle: _organisationSubtitle(organisation),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _organisationSubtitle(Organisation organisation) {
    final parts = <String>[];

    if (organisation.city != null && organisation.city!.isNotEmpty) {
      parts.add(organisation.city!);
    }
    if (organisation.state != null && organisation.state!.isNotEmpty) {
      parts.add(organisation.state!);
    }

    return parts.isEmpty ? null : Text(parts.join(', '));
  }
}
