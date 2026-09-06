import 'package:flutter/material.dart';
import '../models/beneficiary.dart';
import 'impact_page.dart' show beneficiaryImage;
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_settings_menu.dart';

class BeneficiaryDetailPage extends StatelessWidget {
  const BeneficiaryDetailPage({super.key, required this.beneficiary});
  final Beneficiary beneficiary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: Text(l10n.impactStoryTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Hero(
            tag: 'beneficiary-${beneficiary.id}',
            child: beneficiaryImage(beneficiary.primaryImageUrl, height: 240, borderRadius: BorderRadius.circular(24), iconSize: 100),
          ),
          if (beneficiary.gallery.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: beneficiary.gallery.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      beneficiary.gallery[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_rounded),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(beneficiary.name, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Chip(label: Text(beneficiary.cause)),
          const SizedBox(height: 20),
          _Stat(label: l10n.supportedInLabel, value: beneficiary.supportedYear.toString(), icon: Icons.calendar_today_rounded),
          _Stat(label: l10n.contribution, value: '₹${beneficiary.contributionAmount.toStringAsFixed(0)}', icon: Icons.volunteer_activism_rounded),
          if (beneficiary.organisationName != null)
            _Stat(label: l10n.supportedThrough, value: beneficiary.organisationName!, icon: Icons.account_balance_rounded),
          const SizedBox(height: 26),
          Text(l10n.theirStory, style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            beneficiary.story ?? l10n.impactDefaultStory,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFFFF8ED), borderRadius: BorderRadius.circular(18)),
            child: Text(l10n.impactThankYou),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label; final String value; final IconData icon;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children:[Icon(icon,color:const Color(0xFF6E1A14)),const SizedBox(width:12),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:Theme.of(context).textTheme.bodySmall),Text(value,style:Theme.of(context).textTheme.titleMedium)])]),
  );
}