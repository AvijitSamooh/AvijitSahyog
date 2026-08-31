import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../causes/providers/causes_providers.dart';
import '../models/create_donation.dart';
import '../providers/donation_providers.dart';

class DonationPage extends ConsumerStatefulWidget {
  const DonationPage({super.key, required this.initialCauseId, required this.initialCauseName});
  final String initialCauseId;
  final String initialCauseName;
  @override
  ConsumerState<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends ConsumerState<DonationPage> {
  final _amountController = TextEditingController();
  final Set<String> _selectedCauseIds = {};
  int? _selectedAmount;
  bool _submitting = false;
  static const _amounts = [100, 500, 1000, 2000];

  @override
  void initState() { super.initState(); _selectedCauseIds.add(widget.initialCauseId); }
  @override
  void dispose() { _amountController.dispose(); super.dispose(); }
  double get _totalAmount => double.tryParse(_amountController.text.trim()) ?? 0;

  void _selectAmount(int amount) => setState(() { _selectedAmount = amount; _amountController.text = amount.toString(); });
  void _onTotalChanged(String value) { final parsed = double.tryParse(value.trim()); setState(() { _selectedAmount = parsed != null && _amounts.contains(parsed.toInt()) ? parsed.toInt() : null; }); }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final total = _totalAmount;
    if (total <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.donationInvalidAmount))); return; }
    if (_selectedCauseIds.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectCauses))); return; }
    final ids = _selectedCauseIds.toList(growable: false);
    final totalPaise = (total * 100).round();
    final base = totalPaise ~/ ids.length;
    final remainder = totalPaise % ids.length;
    final allocations = <CreateDonationAllocation>[
      for (var index = 0; index < ids.length; index++)
        CreateDonationAllocation(causeId: ids[index], amount: ((base + (index < remainder ? 1 : 0)) / 100).toStringAsFixed(2)),
    ];
    setState(() => _submitting = true);
    try {
      await ref.read(donationRepositoryProvider).createDonation(CreateDonation(amount: total.toStringAsFixed(2), allocations: allocations));
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (context) => AlertDialog(title: Text(l10n.donationCreatedTitle), content: Text(l10n.donationCreatedMessage), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.done))]));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.donationCreateError)));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final causesAsync = ref.watch(causesProvider(Localizations.localeOf(context).languageCode));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.donateTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6E1A14), Color(0xFF4C120D)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFC89B3C))), child: Text(widget.initialCauseName, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white))),
        const SizedBox(height: 28),
        Text(l10n.chooseAmount, style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _amounts.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5), itemBuilder: (context, index) { final amount = _amounts[index]; return OutlinedButton(key: ValueKey('donation_amount_$amount'), onPressed: () => _selectAmount(amount), style: OutlinedButton.styleFrom(backgroundColor: _selectedAmount == amount ? const Color(0xFFFCE8C9) : Colors.white), child: Text('₹ $amount')); }),
        const SizedBox(height: 18),
        TextField(key: const ValueKey('donation_amount_input'), controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: _onTotalChanged, decoration: InputDecoration(labelText: l10n.customAmount, prefixText: '₹ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 28),
        Text(l10n.shareAcrossCauses, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(l10n.selectCauses, style: theme.textTheme.bodyMedium),
        causesAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (_, _) => Text(l10n.causesLoadError),
          data: (causes) => Column(children: causes.map((cause) {
            final selected = _selectedCauseIds.contains(cause.id);
            return CheckboxListTile(key: ValueKey('donation_cause_${cause.id}'), value: selected, title: Text(cause.name), subtitle: _totalAmount > 0 && selected ? Text('₹ ${((_totalAmount * 100).round() ~/ _selectedCauseIds.length / 100).toStringAsFixed(2)}') : null, onChanged: (value) => setState(() { if (value == true) { _selectedCauseIds.add(cause.id); } else { _selectedCauseIds.remove(cause.id); } }));
          }).toList(growable: false)),
        ),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFF8ED), borderRadius: BorderRadius.circular(16)), child: Text(l10n.causeAllocationInfo)),
        const SizedBox(height: 18),
        FilledButton.icon(key: const ValueKey('donation_submit'), onPressed: _submitting || _totalAmount <= 0 ? null : _submit, icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.favorite_rounded), label: Text(l10n.donateNow)),
        const SizedBox(height: 12),
        Text(l10n.donationPaymentLater, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      ]),
    );
  }
}
