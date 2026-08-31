import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../donations/presentation/donation_page.dart';
import '../models/organisation.dart';
import '../providers/causes_providers.dart';

class CauseDetailPage extends ConsumerWidget {
  const CauseDetailPage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final causeAsync = ref.watch(causeProvider((slug: slug, languageCode: languageCode)));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cause Details')),
      body: causeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _CauseErrorState(),
        data: (cause) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6E1A14), Color(0xFF4C120D)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.volunteer_activism_rounded,
                      color: Color(0xFFF5A623), size: 32),
                  const SizedBox(height: 18),
                  Text(cause.name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: Colors.white)),
                  if (cause.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(
                      cause.description!,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: Colors.white.withValues(alpha: .88)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DonationPage(
                          initialCauseId: cause.id,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: const Color(0xFF4C120D),
                    ),
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Support this Cause'),
                  ),
                ],
              ),
            ),
            if (cause.organisations.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text('How your contribution reaches people',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Your contribution supports this cause. These affiliated organisations help turn that support into real impact.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...cause.organisations.map(
                (organisation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrganisationInfoCard(organisation: organisation),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrganisationInfoCard extends StatelessWidget {
  const _OrganisationInfoCard({required this.organisation});
  final Organisation organisation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = [
      if (organisation.city?.isNotEmpty == true) organisation.city!,
      if (organisation.state?.isNotEmpty == true) organisation.state!,
    ].join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8C9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_rounded,
                  color: Color(0xFF6E1A14)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(organisation.name, style: theme.textTheme.titleMedium),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(location, style: theme.textTheme.bodyMedium),
                  ],
                  if (organisation.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      organisation.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CauseErrorState extends StatelessWidget {
  const _CauseErrorState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Unable to load this cause right now.'),
        ),
      );
}
