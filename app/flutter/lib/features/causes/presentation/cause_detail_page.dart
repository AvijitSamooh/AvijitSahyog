import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_settings_menu.dart';
import '../../../l10n/app_localizations.dart';

import '../../donations/presentation/donation_page.dart';
import '../models/organisation.dart';
import '../providers/causes_providers.dart';
import 'organisation_detail_page.dart';

class CauseDetailPage extends ConsumerWidget {
  const CauseDetailPage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final causeAsync = ref.watch(causeProvider((slug: slug, languageCode: languageCode)));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppPageScaffold(
      title: Text(l10n.causeDetailsTitle),
      body: causeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CauseErrorState(
          message: l10n.causeLoadError,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(causeProvider((slug: slug, languageCode: languageCode))),
        ),
        data: (cause) => RefreshIndicator(
          onRefresh: () async => ref.refresh(
            causeProvider((slug: slug, languageCode: languageCode)).future,
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    label: Text(l10n.supportThisCause),
                  ),
                ],
              ),
            ),
            if (cause.organisations.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(l10n.causeReachTitle,
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                l10n.causeReachDescription,
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
    final l10n = AppLocalizations.of(context)!;
    final location = [
      if (organisation.city?.isNotEmpty == true) organisation.city!,
      if (organisation.state?.isNotEmpty == true) organisation.state!,
    ].join(', ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrganisationDetailPage(organisation: organisation),
          ),
        ),
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
                child: organisation.logoUrl?.trim().isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          organisation.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.account_balance_rounded,
                            color: Color(0xFF6E1A14),
                          ),
                        ),
                      )
                    : const Icon(
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
                    if (_hasValidMobileNumber(organisation.mobileNumber)) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: ValueKey('affiliate_call_${organisation.id}'),
                            tooltip: l10n.affiliateCall,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.phone_rounded),
                            onPressed: () => _callAffiliate(context, organisation.mobileNumber!),
                          ),
                          IconButton(
                            key: ValueKey('affiliate_whatsapp_${organisation.id}'),
                            tooltip: l10n.affiliateWhatsApp,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chat_rounded),
                            onPressed: () => _openWhatsApp(context, organisation.mobileNumber!),
                          ),
                        ],
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
bool _hasValidMobileNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^(?:91)?[6-9]\d{9}$').hasMatch(digits);
  }

  String _whatsAppNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 ? '91$digits' : digits;
  }

  Future<void> _callAffiliate(BuildContext context, String value) async {
    final launched = await launchUrl(Uri(scheme: 'tel', path: value));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.affiliateCallFailed)),
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String value) async {
    final uri = Uri.parse('https://wa.me/${_whatsAppNumber(value)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.affiliateWhatsAppFailed)),
      );
    }
  }
}
class _CauseErrorState extends StatelessWidget {
  const _CauseErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
            ],
          ),
        ),
      );
}
