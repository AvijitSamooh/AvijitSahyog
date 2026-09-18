import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/help_applications_providers.dart';

class AdminApplicationsPage extends ConsumerStatefulWidget {
  const AdminApplicationsPage({super.key});
  @override
  ConsumerState<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends ConsumerState<AdminApplicationsPage> {
  String? _type;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _items = await ref.read(helpApplicationsRepositoryProvider).adminList(type: _type);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final score = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.voteScore),
        children: List.generate(5, (index) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, index + 1),
          child: Text((index + 1).toString()),
        )),
      ),
    );
    if (score == null) return;
    await ref.read(helpApplicationsRepositoryProvider).vote(item['id'] as String, score);
    await _load();
  }

  Future<void> _review(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final type = item['type'] as String;
    final isSamman = type == 'PRATIBHA_SAMMAN';
    final decision = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.reviewDecision),
        children: [
          if (!isSamman) SimpleDialogOption(onPressed: () => Navigator.pop(context, 'APPROVE'), child: Text(l10n.approveForDonation)),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'REJECT'), child: Text(l10n.rejectApplication)),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 'CLARIFICATION_REQUIRED'), child: Text(l10n.requestClarification)),
          if (isSamman) ...[
            SimpleDialogOption(onPressed: () => Navigator.pop(context, 'CONSIDER_FOR_SAMMAN'), child: Text(l10n.considerForSamman)),
            SimpleDialogOption(onPressed: () => Navigator.pop(context, 'NOT_SELECTED'), child: Text(l10n.notSelected)),
          ],
        ],
      ),
    );
    if (decision == null) return;

    double? approvedAmount;
    String? reason;
    if (decision == 'APPROVE') {
      final controller = TextEditingController();
      approvedAmount = double.tryParse((await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.approvedAmount),
          content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.saveReview))],
        ),
      ) ?? ''));
      controller.dispose();
    } else if (decision == 'REJECT' || decision == 'CLARIFICATION_REQUIRED') {
      final controller = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(decision == 'REJECT' ? l10n.rejectionReason : l10n.clarification),
          content: TextField(controller: controller, minLines: 3, maxLines: 6),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.saveReview))],
        ),
      );
      controller.dispose();
    }

    final trimmedReason = reason?.trim();
    final payload = <String, dynamic>{'decision': decision, if (approvedAmount != null) 'approvedAmount': approvedAmount, if (trimmedReason?.isNotEmpty == true) 'reason': trimmedReason};
    await ref.read(helpApplicationsRepositoryProvider).review(item['id'] as String, payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reviewSaved)));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: Text(l10n.adminApplications),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(spacing: 8, children: [
              FilterChip(label: Text(l10n.applicationsTitle), selected: _type == null, onSelected: (_) { setState(() => _type = null); _load(); }),
              FilterChip(label: Text(l10n.educationHelp), selected: _type == 'EDUCATION_ASSISTANCE', onSelected: (_) { setState(() => _type = 'EDUCATION_ASSISTANCE'); _load(); }),
              FilterChip(label: Text(l10n.medicalHelp), selected: _type == 'MEDICAL_HELP', onSelected: (_) { setState(() => _type = 'MEDICAL_HELP'); _load(); }),
              FilterChip(label: Text(l10n.pratibhaSamman), selected: _type == 'PRATIBHA_SAMMAN', onSelected: (_) { setState(() => _type = 'PRATIBHA_SAMMAN'); _load(); }),
            ]),
          ),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
            ? Center(child: Text(_error!))
            : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final votes = item['votes'] as List<dynamic>? ?? [];
                return Card(
                  child: ExpansionTile(
                    title: Text(_typeLabel(l10n, item['type'] as String)),
                    subtitle: Text(_statusLabel(l10n, item['status'] as String)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(alignment: Alignment.centerLeft, child: Text((item['applicant']?['displayName'] ?? item['applicant']?['email'] ?? '').toString())),
                      if (item['requestedAmount'] != null) Align(alignment: Alignment.centerLeft, child: Text(l10n.requestedAmount + ': ₹' + item['requestedAmount'].toString())),
                      if (item['approvedAmount'] != null) Align(alignment: Alignment.centerLeft, child: Text(l10n.approvedAmount + ': ₹' + item['approvedAmount'].toString())),
                      Align(alignment: Alignment.centerLeft, child: Text(l10n.voteAverage + ': ' + ((item['voteAverage'] as num?)?.toStringAsFixed(1) ?? '—'))),
                      Align(alignment: Alignment.centerLeft, child: Text(votes.length.toString() + ' ' + l10n.vote)),
                      Row(children: [
                        TextButton.icon(onPressed: () => _vote(item), icon: const Icon(Icons.how_to_vote_rounded), label: Text(l10n.vote)),
                        const SizedBox(width: 8),
                        FilledButton.icon(onPressed: () => _review(item), icon: const Icon(Icons.rate_review_rounded), label: Text(l10n.reviewDecision)),
                      ]),
                    ],
                  ),
                );
              },
            )),
        ],
      ),
    );
  }
}

String _typeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'MEDICAL_HELP': return l10n.medicalHelp;
    case 'PRATIBHA_SAMMAN': return l10n.pratibhaSamman;
    default: return l10n.educationHelp;
  }
}

String _statusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'SUBMITTED': return l10n.statusSubmitted;
    case 'UNDER_REVIEW': return l10n.statusUnderReview;
    case 'CLARIFICATION_REQUIRED': return l10n.statusClarification;
    case 'APPROVED_FOR_DONATION': return l10n.statusApproved;
    case 'REJECTED': return l10n.statusRejected;
    case 'CONSIDERED_FOR_SAMMAN': return l10n.statusConsidered;
    default: return l10n.statusNotSelected;
  }
}
