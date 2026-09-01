import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/navigation/app_shell_scope.dart';
import '../../../core/widgets/app_navigation_bar.dart';
import '../../../core/widgets/app_settings_menu.dart';
import '../../causes/providers/causes_providers.dart';

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
  final Map<String, TextEditingController> _percentageControllers = {};
  int? _selectedAmount;
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
  void dispose() {
    _amountController.dispose();
    for (final controller in _percentageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
        _percentageControllers.remove(id)?.dispose();
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
    _syncAllocationControllers();
  }

  void _syncAllocationControllers() {
    for (final id in _selectedCauseIds) {
      final percentage = _allocationPercentages[id] ?? 0;
      final controller = _percentageControllers[id];
      if (controller != null && controller.text != percentage.toString()) {
        controller.text = percentage.toString();
      }
    }
  }

  TextEditingController _percentageController(String id, int percentage) {
    return _percentageControllers.putIfAbsent(
      id,
      () => TextEditingController(text: percentage.toString()),
    );
  }

  void _setPercentage(String id, int value) =>
      setState(() => _allocationPercentages[id] = value.clamp(0, 100));

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.donationNotEnabledYet)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final causesAsync = ref.watch(causesProvider(Localizations.localeOf(context).languageCode));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.donateTitle),
        actions: const [AppSettingsMenu()],
      ),
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
                SizedBox(width: 110, child: TextFormField(key: ValueKey('donation_percentage_${cause.id}'), controller: _percentageController(cause.id, percentage), keyboardType: TextInputType.number, textAlign: TextAlign.center, onChanged: (value) => _setPercentage(cause.id, int.tryParse(value) ?? 0), decoration: const InputDecoration(suffixText: '%'))),
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
        FilledButton.icon(key: const ValueKey('donation_submit'), onPressed: _totalAmount <= 0 || _selectedCauseIds.isEmpty || _allocationTotal != 100 ? null : _submit, icon: const Icon(Icons.favorite_rounded), label: Text(l10n.donateNow)),
        const SizedBox(height: 12),
        Text(l10n.donationPaymentLater, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      ]),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          final navigation = AppShellScope.of(context).navigation;
          navigation.select(index);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }
}