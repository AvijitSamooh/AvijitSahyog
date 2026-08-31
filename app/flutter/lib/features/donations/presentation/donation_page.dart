import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../causes/providers/causes_providers.dart';
import '../models/create_donation.dart';
import '../providers/donation_providers.dart';

class DonationPage extends ConsumerStatefulWidget {
  const DonationPage({super.key, this.initialCauseId});
  final String? initialCauseId;
  @override
  ConsumerState<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends ConsumerState<DonationPage> {
  final _amountController = TextEditingController();
  final Set<String> _selectedCauseIds = {};
  final Map<String, int> _allocationPercentages = {};
  int? _selectedAmount;
  bool _submitting = false;
  static const _amounts = [100, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    if (widget.initialCauseId != null) {
      _selectedCauseIds.add(widget.initialCauseId!);
      _allocationPercentages[widget.initialCauseId!] = 100;
    }
  }

  @override
  void dispose() { _amountController.dispose(); super.dispose(); }

  double get _totalAmount => double.tryParse(_amountController.text.trim()) ?? 0;
  int get _allocationTotal => _selectedCauseIds.fold(0, (total, id) => total + (_allocationPercentages[id] ?? 0));

  void _selectAmount(int amount) => setState(() { _selectedAmount = amount; _amountController.text = amount.toString(); });
  void _onTotalChanged(String value) { final parsed = double.tryParse(value.trim()); setState(() { _selectedAmount = parsed != null && _amounts.contains(parsed.toInt()) ? parsed.toInt() : null; }); }
  void _toggleCause(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedCauseIds.add(id);
      } else {
        _selectedCauseIds.remove(id);
        _allocationPercentages.remove(id);
      }
      _applyEqualDistribution();
    });
  }

  void _applyEqualDistribution() {
    if (_selectedCauseIds.isEmpty) return;
    final ids = _selectedCauseIds.toList(growable: false);
    final base = 100 ~/ ids.length;
    var remainder = 100 % ids.length;
    for (final id in ids) {
      _allocationPercentages[id] = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
    }
  }

  void _setPercentage(String id, int value) =>
      setState(() => _allocationPercentages[id] = value.clamp(0, 100));

  List<CreateDonationAllocation> _buildAllocations() {
    final totalPaise = (_totalAmount * 100).round();
    var assigned = 0;
    final ids = _selectedCauseIds.toList(growable: false);
    return [
      for (var i = 0; i < ids.length; i++)
        CreateDonationAllocation(
          causeId: ids[i],
          amount: (() {
            final paise = i == ids.length - 1 ? totalPaise - assigned : (totalPaise * (_allocationPercentages[ids[i]] ?? 0) / 100).round();
            assigned += paise;
            return (paise / 100).toStringAsFixed(2);
          })(),
        ),
    ];
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_totalAmount <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.donationInvalidAmount))); return; }
    if (_selectedCauseIds.isEmpty || _allocationTotal != 100) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.allocationMustTotal100))); return; }
    setState(() => _submitting = true);
    try {
      await ref.read(donationRepositoryProvider).createDonation(CreateDonation(amount: _totalAmount.toStringAsFixed(2), allocations: _buildAllocations()));
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
        Text(l10n.chooseAmount, style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _amounts.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5), itemBuilder: (context, index) {
          final amount = _amounts[index];
          return OutlinedButton(key: ValueKey('donation_amount_$amount'), onPressed: () => _selectAmount(amount), style: OutlinedButton.styleFrom(backgroundColor: _selectedAmount == amount ? const Color(0xFFFCE8C9) : Colors.white), child: Text('₹ $amount'));
        }),
        const SizedBox(height: 18),
        TextField(key: const ValueKey('donation_amount_input'), controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: _onTotalChanged, decoration: InputDecoration(labelText: l10n.customAmount, prefixText: '₹ ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 28),
        Text(l10n.shareAcrossCauses, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(l10n.selectCauses, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        causesAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (_, _) => Text(l10n.causesLoadError),
          data: (causes) => Column(children: causes.map((cause) {
            final selected = _selectedCauseIds.contains(cause.id);
            final percentage = _allocationPercentages[cause.id] ?? 0;
            return Card(child: Column(children: [
              CheckboxListTile(key: ValueKey('donation_cause_${cause.id}'), value: selected, title: Text(cause.name), onChanged: (value) => _toggleCause(cause.id, value ?? false)),
              if (selected) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Row(children: [
                Expanded(child: Text(l10n.allocationPercentage)),
                SizedBox(width: 110, child: TextFormField(key: ValueKey('donation_percentage_${cause.id}'), initialValue: percentage.toString(), keyboardType: TextInputType.number, textAlign: TextAlign.center, onChanged: (value) => _setPercentage(cause.id, int.tryParse(value) ?? 0), decoration: const InputDecoration(suffixText: '%'))),
                const SizedBox(width: 12),
                if (_totalAmount > 0) Text('₹ ${(_totalAmount * percentage / 100).toStringAsFixed(2)}'),
              ])),
            ]));
          }).toList(growable: false)),
        ),
        const SizedBox(height: 12),
        Text('${l10n.totalAllocation}: $_allocationTotal%', key: const ValueKey('donation_allocation_total'), style: theme.textTheme.titleMedium?.copyWith(color: _allocationTotal == 100 ? Colors.green.shade700 : Colors.red.shade700)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFF8ED), borderRadius: BorderRadius.circular(16)), child: Text(l10n.causeAllocationInfo)),
        const SizedBox(height: 18),
        FilledButton.icon(key: const ValueKey('donation_submit'), onPressed: _submitting || _totalAmount <= 0 || _selectedCauseIds.isEmpty || _allocationTotal != 100 ? null : _submit, icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.favorite_rounded), label: Text(l10n.donateNow)),
        const SizedBox(height: 12),
        Text(l10n.donationPaymentLater, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      ]),
    );
  }
}
