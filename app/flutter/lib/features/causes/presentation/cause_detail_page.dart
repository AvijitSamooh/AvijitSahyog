import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../donations/presentation/donation_page.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.causesTitle),
      ),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6E1A14), Color(0xFF4C120D)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFC89B3C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✦',
                    style: TextStyle(
                      color: Color(0xFFF5A623),
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cause.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                  if (cause.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(
                      cause.description!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (cause.organisations.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                l10n.affiliatedOrganisations,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.welcomeSubtitle,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              ...cause.organisations.map(
                (organisation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrganisationCard(
                    organisation: organisation,
                    causeId: cause.id,
                    causeName: cause.name,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrganisationCard extends StatelessWidget {
  const _OrganisationCard({
    required this.organisation,
    required this.causeId,
    required this.causeName,
  });

  final Organisation organisation;
  final String causeId;
  final String causeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final location = _organisationSubtitle(organisation);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE8C9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF6E1A14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(organisation.name, style: theme.textTheme.titleMedium),
                      if (location != null) ...[
                        const SizedBox(height: 5),
                        location,
                      ],
                      if (organisation.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        Text(
                          organisation.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DonationPage(
                        causeId: causeId,
                        causeName: causeName,
                        organisation: organisation,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.favorite_rounded, size: 18),
                label: Text(l10n.donateNow),
              ),
            ),
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

    if (parts.isEmpty) return null;

    return Text(
      parts.join(', '),
      style: const TextStyle(
        color: Color(0xFF9A574C),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
