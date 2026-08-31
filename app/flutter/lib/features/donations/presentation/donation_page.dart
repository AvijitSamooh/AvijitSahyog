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
  int _step = 0;
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
  void _toggleCause(String id, bool selected) => setState(() { if (selected) { _selectedCauseIds.add(id); _allocationPercentages[id] ??= 0; } else { _selectedCauseIds.remove(id); _allocationPercentages.remove(id); } });
  void _setPercentage(String id, int value) => setState(() => _allocationPercentages[id] = value.clamp(0, 100));

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
      body: causesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.causesLoadError)),
        data: (causes) {
          final selectedCauses = causes.where((cause) => _selectedCauseIds.contains(cause.id)).toList();
          final canContinue = _step == 0 ? _selectedCauseIds.isNotEmpty : _totalAmount > 0 && _allocationTotal == 100;
          return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), children: [
            Row(children: List.generate(3, (index) => Expanded(child: Column(children: [
              CircleAvatar(radius: 16, backgroundColor: index <= _step ? theme.colorScheme.primary : Colors.grey.shade300, child: Text((index + 1).toString(), style: TextStyle(color: index <= _step ? Colors.white : Colors.black54))),
              const SizedBox(height: 6), Text(index == 0 ? l10n.selectCauses : index == 1 ? l10n.shareAcrossCauses : l10n.donateNow, textAlign: TextAlign.center, maxLines: 2, style: theme.textTheme.labelSmall),
            ])))),
            const SizedBox(height: 28),
            if (_step == 0) ...[
              Text(l10n.selectCauses, style: theme.textTheme.titleLarge), const SizedBox(height: 8), Text(l10n.causeAllocationInfo), const SizedBox(height: 12),
              ...causes.map((cause) => Card(child: CheckboxListTile(key: ValueKey("donation_cause_" + cause.id), value: _selectedCauseIds.contains(cause.id), title: Text(cause.name), subtitle: cause.description == null ? null : Text(cause.description!), onChanged: (value) => _toggleCause(cause.id, value ?? false)))),
            ] else if (_step == 1) ...[
              Text(l10n.chooseAmount, style: theme.textTheme.titleLarge), const SizedBox(height: 14),
              GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _amounts.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5), itemBuilder: (context, index) { final amount = _amounts[index]; return OutlinedButton(key: ValueKey("donation_amount_" + amount.toString()), onPressed: () => _selectAmount(amount), child: Text("₹ " + amount.toString())); }),
              const SizedBox(height: 16), TextField(key: const ValueKey("donation_amount_input"), controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: _onTotalChanged, decoration: InputDecoration(labelText: l10n.customAmount, prefixText: "₹ ", border: const OutlineInputBorder())),
              const SizedBox(height: 28), Text(l10n.shareAcrossCauses, style: theme.textTheme.titleLarge),
              ...selectedCauses.map((cause) { final percentage = _allocationPercentages[cause.id] ?? 0; return Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Expanded(child: Text(cause.name)), SizedBox(width: 100, child: TextFormField(key: ValueKey("donation_percentage_" + cause.id), initialValue: percentage.toString(), keyboardType: TextInputType.number, onChanged: (value) => _setPercentage(cause.id, int.tryParse(value) ?? 0), decoration: const InputDecoration(suffixText: "%"))), const SizedBox(width: 12), if (_totalAmount > 0) Text("₹ " + (_totalAmount * percentage / 100).toStringAsFixed(2))]))); }),
              const SizedBox(height: 12), Text(l10n.totalAllocation + ": " + _allocationTotal.toString() + "%", key: const ValueKey("donation_allocation_total"), style: theme.textTheme.titleMedium),
            ] else ...[
              Text(l10n.donateTitle, style: theme.textTheme.titleLarge), const SizedBox(height: 8), Text(l10n.causeAllocationInfo), const SizedBox(height: 16),
              ...selectedCauses.map((cause) { final percentage = _allocationPercentages[cause.id] ?? 0; return Card(child: ListTile(title: Text(cause.name), subtitle: Text(percentage.toString() + "%"), trailing: Text("₹ " + (_totalAmount * percentage / 100).toStringAsFixed(2)))); }),
              Card(child: ListTile(title: Text(l10n.chooseAmount), trailing: Text("₹ " + _totalAmount.toStringAsFixed(2), style: theme.textTheme.titleMedium))),
              const SizedBox(height: 12), Text(l10n.donationPaymentLater, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 28),
            Row(children: [
              if (_step > 0) ...[Expanded(child: OutlinedButton(key: const ValueKey("donation_back"), onPressed: _submitting ? null : () => setState(() => _step--), child: const Icon(Icons.arrow_back_rounded))), const SizedBox(width: 12)],
              Expanded(child: FilledButton.icon(key: const ValueKey("donation_primary_action"), onPressed: _submitting ? null : (_step == 2 ? _submit : (canContinue ? () => setState(() => _step++) : null)), icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_step == 2 ? Icons.favorite_rounded : Icons.arrow_forward_rounded), label: Text(_step == 2 ? l10n.donateNow : _step == 0 ? l10n.shareAcrossCauses : l10n.donateTitle))),
            ]),
          ]);
        },
      ),
    );
  }
}