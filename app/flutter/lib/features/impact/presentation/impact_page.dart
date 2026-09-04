import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/beneficiary.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/beneficiaries_providers.dart';
import 'beneficiary_detail_page.dart';

Widget beneficiaryImage(String? photoUrl, {required double height, required BorderRadius borderRadius, double iconSize = 64}) {
  return ClipRRect(
    borderRadius: borderRadius,
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: photoUrl != null && photoUrl.trim().isNotEmpty
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _beneficiaryPlaceholder(iconSize),
            )
          : _beneficiaryPlaceholder(iconSize),
    ),
  );
}

Widget _beneficiaryPlaceholder(double iconSize) => Container(
  color: const Color(0xFFFCE8C9),
  child: Icon(Icons.person_rounded, size: iconSize, color: const Color(0xFF6E1A14)),
);

class ImpactPage extends ConsumerStatefulWidget {
  const ImpactPage({super.key});
  @override ConsumerState<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends ConsumerState<ImpactPage> {
  final _search = TextEditingController();
  String _sort = 'Newest';

  String? get _apiSort => switch (_sort) {
    'Name A–Z' => 'name_asc',
    'Highest amount' => 'amount_desc',
    'Lowest amount' => 'amount_asc',
    _ => null,
  };

  @override void dispose() { _search.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final beneficiaries = ref.watch(beneficiariesProvider((search: _search.text.trim(), sort: _apiSort)));
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(AppLocalizations.of(context)!.impactSubtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          TextField(
            key: const ValueKey('beneficiary_search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: AppLocalizations.of(context)!.impactSearch, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('beneficiary_sort'),
            initialValue: _sort,
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.impactSort, border: const OutlineInputBorder()),
            items: const ['Newest', 'Name A–Z', 'Highest amount', 'Lowest amount'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (value) => setState(() => _sort = value ?? 'Newest'),
          ),
          const SizedBox(height: 24),
          beneficiaries.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Icon(Icons.cloud_off_rounded, size: 44),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.impactLoadError),
                TextButton(onPressed: () => ref.invalidate(beneficiariesProvider((search: _search.text.trim(), sort: _apiSort))), child: Text(AppLocalizations.of(context)!.tryAgain)),
              ]),
            ),
            data: (items) => items.isEmpty
                ? Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(AppLocalizations.of(context)!.impactNoResults)))
                : Column(children: items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _Card(item))).toList()),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.x);
  final Beneficiary x;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Hero(tag: 'beneficiary-${x.id}', child: beneficiaryImage(x.primaryImageUrl, height: 150, borderRadius: BorderRadius.circular(14))),
    const SizedBox(height: 16),
    Text(x.name, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 4),
    Text(x.cause),
    const SizedBox(height: 14),
    Text(AppLocalizations.of(context)!.supportedIn(x.supportedYear)),
    Text(AppLocalizations.of(context)!.contributionAmount(x.contributionAmount.toStringAsFixed(0))),
    const SizedBox(height: 10),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BeneficiaryDetailPage(beneficiary: x))), child: Text(AppLocalizations.of(context)!.viewStory))),
  ])));
}
