import 'package:flutter/material.dart';
import '../models/beneficiary.dart';
import 'impact_page.dart' show beneficiaryImage;

class BeneficiaryDetailPage extends StatelessWidget {
  const BeneficiaryDetailPage({super.key, required this.beneficiary});
  final Beneficiary beneficiary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Impact Story')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Hero(
            tag: 'beneficiary-${beneficiary.id}',
            child: beneficiaryImage(beneficiary.photoUrl, height: 240, borderRadius: BorderRadius.circular(24), iconSize: 100),
          ),
          const SizedBox(height: 24),
          Text(beneficiary.name, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Chip(label: Text(beneficiary.cause)),
          const SizedBox(height: 20),
          _Stat(label: 'Supported in', value: beneficiary.supportedYear.toString(), icon: Icons.calendar_today_rounded),
          _Stat(label: 'Contribution', value: '₹${beneficiary.contributionAmount.toStringAsFixed(0)}', icon: Icons.volunteer_activism_rounded),
          if (beneficiary.organisationName != null)
            _Stat(label: 'Supported through', value: beneficiary.organisationName!, icon: Icons.account_balance_rounded),
          const SizedBox(height: 26),
          Text('Their Story', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            beneficiary.story ?? 'Every contribution has a human story behind it. This support helped create an opportunity and move one life forward.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFFFF8ED), borderRadius: BorderRadius.circular(18)),
            child: const Text('Thank you for being part of stories like this. Your generosity helps turn compassion into meaningful impact.'),
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