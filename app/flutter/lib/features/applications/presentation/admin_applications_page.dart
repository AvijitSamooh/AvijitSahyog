import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../../../l10n/app_localizations.dart';
import '../models/application_window.dart';
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

  Future<void> _startWindow(String type) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final current = ref.read(applicationWindowsProvider).valueOrNull?.where((w) => w.type == type).firstOrNull;
    final defaultEventDate = type == 'PRATIBHA_SAMMAN' ? DateTime(2026, 10, 25) : (current?.eventAt ?? now.add(const Duration(days: 30)));

    final date = await showDatePicker(
      context: context,
      initialDate: current?.startsAt.toLocal() ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: l10n.applicationStartDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current?.startsAt.toLocal() ?? now),
      helpText: l10n.applicationStartTime,
    );
    if (time == null || !mounted) return;

    final startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    DateTime? registrationEndsAt;
    if (type == 'PRATIBHA_SAMMAN') {
      registrationEndsAt = await showDatePicker(
        context: context,
        initialDate: current?.registrationEndsAt?.toLocal() ?? startsAt.add(const Duration(days: 7)),
        firstDate: DateTime(date.year, date.month, date.day),
        lastDate: DateTime(now.year + 2, 12, 31),
        helpText: l10n.registrationLastDate,
      );
      if (registrationEndsAt == null || !mounted) return;
      registrationEndsAt = DateTime(registrationEndsAt.year, registrationEndsAt.month, registrationEndsAt.day, 23, 59, 59);
    }

    DateTime? eventAt;
    if (type == 'PRATIBHA_SAMMAN') {
      eventAt = await showDatePicker(
        context: context,
        initialDate: current?.eventAt?.toLocal() ?? defaultEventDate,
        firstDate: DateTime(date.year, date.month, date.day),
        lastDate: DateTime(now.year + 2, 12, 31),
        helpText: l10n.eventDate,
      );
      if (eventAt == null || !mounted) return;
      eventAt = DateTime(eventAt.year, eventAt.month, eventAt.day);
    }

    try {
      await ref.read(helpApplicationsRepositoryProvider).startApplicationWindow(
        type: type,
        startsAt: startsAt,
        registrationEndsAt: registrationEndsAt,
        eventAt: eventAt,
      );
      ref.invalidate(applicationWindowsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.applicationWindowSaved)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.applicationWindowSaveFailed)),
        );
      }
    }
  }

  Future<void> _closeWindow(String type) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.applicationWindowCloseTitle),
        content: Text(l10n.applicationWindowCloseConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.closeApplications),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(helpApplicationsRepositoryProvider).closeApplicationWindow(type);
      ref.invalidate(applicationWindowsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.applicationWindowClosed)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.applicationWindowSaveFailed)),
        );
      }
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
    if (score == null || !mounted) return;
    try { await ref.read(helpApplicationsRepositoryProvider).vote(item['id'] as String, score); await _load(); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationActionFailed))); }
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
    if (decision == null || !mounted) return;

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
      if (!mounted) return;
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
    final payloadReason = trimmedReason?.isNotEmpty == true ? trimmedReason : null;
    final payload = <String, dynamic>{'decision': decision, 'approvedAmount': ?approvedAmount, 'reason': ?payloadReason};
    try { await ref.read(helpApplicationsRepositoryProvider).review(item['id'] as String, payload); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reviewSaved))); await _load(); } } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationActionFailed))); }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final windows = ref.watch(applicationWindowsProvider);

    return AppPageScaffold(
      title: Text(l10n.adminApplications),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ApplicationWindowAdminPanel(
                key: const ValueKey('application_window_management'),
                windows: windows,
                typeLabel: (type) => _typeLabel(l10n, type),
                formatDateTime: (value) => _windowDateTime(context, value),
                onStart: _startWindow,
                onClose: _closeWindow,
              ),
            ),
            SliverToBoxAdapter(
              child: const _ApplicationRulesAdminPanel(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(l10n.applicationsTitle),
                      selected: _type == null,
                      onSelected: (_) {
                        setState(() => _type = null);
                        _load();
                      },
                    ),
                    FilterChip(
                      label: Text(l10n.educationHelp),
                      selected: _type == 'EDUCATION_ASSISTANCE',
                      onSelected: (_) {
                        setState(() => _type = 'EDUCATION_ASSISTANCE');
                        _load();
                      },
                    ),
                    FilterChip(
                      label: Text(l10n.medicalHelp),
                      selected: _type == 'MEDICAL_HELP',
                      onSelected: (_) {
                        setState(() => _type = 'MEDICAL_HELP');
                        _load();
                      },
                    ),
                    FilterChip(
                      label: Text(l10n.pratibhaSamman),
                      selected: _type == 'PRATIBHA_SAMMAN',
                      onSelected: (_) {
                        setState(() => _type = 'PRATIBHA_SAMMAN');
                        _load();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(_error!)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _items[index];
                      final votes = item['votes'] as List<dynamic>? ?? [];
                      return Card(
                        child: ExpansionTile(
                          title: Text(_typeLabel(l10n, item['type'] as String)),
                          subtitle: Text(_statusLabel(l10n, item['status'] as String)),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                (item['applicant']?['displayName'] ??
                                        item['applicant']?['email'] ??
                                        '')
                                    .toString(),
                              ),
                            ),
                            if (item['requestedAmount'] != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${l10n.requestedAmount}: ₹${item['requestedAmount']}',
                                ),
                              ),
                            if (item['approvedAmount'] != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${l10n.approvedAmount}: ₹${item['approvedAmount']}',
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${l10n.voteAverage}: ${((item['voteAverage'] as num?)?.toStringAsFixed(1) ?? '—')}',
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('${votes.length} ${l10n.vote}'),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _vote(item),
                                  icon: const Icon(Icons.how_to_vote_rounded),
                                  label: Text(l10n.vote),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () => _review(item),
                                  icon: const Icon(Icons.rate_review_rounded),
                                  label: Text(l10n.reviewDecision),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationRulesAdminPanel extends ConsumerStatefulWidget {
  const _ApplicationRulesAdminPanel();
  @override ConsumerState<_ApplicationRulesAdminPanel> createState() => _ApplicationRulesAdminPanelState();
}

class _ApplicationRulesAdminPanelState extends ConsumerState<_ApplicationRulesAdminPanel> {
  String _ruleTypeLabel(AppLocalizations l10n, String type) => switch (type) {
    'MEDICAL_HELP' => l10n.medicalHelp,
    'PRATIBHA_SAMMAN' => l10n.pratibhaSamman,
    _ => l10n.educationHelp,
  };

  String _type = 'PRATIBHA_SAMMAN';
  bool _loading = true;
  List<Map<String, dynamic>> _rules = const [];

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rules = await ref.read(helpApplicationsRepositoryProvider).adminApplicationRules(_type);
      if (mounted) setState(() { _rules = rules; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _editRule([Map<String, dynamic>? rule]) async {
    final l10n = AppLocalizations.of(context)!;
    final translations = <String, String>{};
    for (final item in (rule?['translations'] as List<dynamic>? ?? const [])) {
      final map = item as Map<String, dynamic>;
      translations[map['language'] as String] = map['text'] as String? ?? '';
    }
    final en = TextEditingController(text: translations['en'] ?? '');
    final hi = TextEditingController(text: translations['hi'] ?? '');
    final mr = TextEditingController(text: translations['mr'] ?? '');
    final gu = TextEditingController(text: translations['gu'] ?? '');
    final order = TextEditingController(text: (rule?['displayOrder'] ?? (_rules.length + 1)).toString());
    var active = rule?['isActive'] as bool? ?? true;
    final save = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(rule == null ? l10n.addApplicationRule : l10n.editApplicationRule),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: order, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.ruleDisplayOrder)),
        TextField(controller: en, maxLines: 3, decoration: InputDecoration(labelText: l10n.ruleEnglish)),
        TextField(controller: hi, maxLines: 3, decoration: InputDecoration(labelText: l10n.ruleHindi)),
        TextField(controller: mr, maxLines: 3, decoration: InputDecoration(labelText: l10n.ruleMarathi)),
        TextField(controller: gu, maxLines: 3, decoration: InputDecoration(labelText: l10n.ruleGujarati)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.ruleActive), value: active, onChanged: (value) => setDialogState(() => active = value)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.saveRule))],
    )));
    if (save != true || !mounted) { for (final x in [en, hi, mr, gu, order]) { x.dispose(); } return; }
    final values = {'en': en.text.trim(), 'hi': hi.text.trim(), 'mr': mr.text.trim(), 'gu': gu.text.trim()};
    if (values.values.any((value) => value.isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.allRuleTranslationsRequired))); for (final x in [en, hi, mr, gu, order]) { x.dispose(); } return; }
    final payload = {'type': _type, 'displayOrder': int.tryParse(order.text.trim()) ?? (_rules.length + 1), 'isActive': active, 'translations': values.entries.map((entry) => {'language': entry.key, 'text': entry.value}).toList(growable: false)};
    try {
      final repo = ref.read(helpApplicationsRepositoryProvider);
      if (rule == null) { await repo.createAdminApplicationRule(payload); } else { final updatePayload = Map<String, dynamic>.from(payload)..remove('type'); await repo.updateAdminApplicationRule(rule['id'] as String, updatePayload); }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ruleSaved))); await _load(); }
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ruleActionFailed))); }
    finally { for (final x in [en, hi, mr, gu, order]) { x.dispose(); } }
  }

  Future<void> _deleteRule(Map<String, dynamic> rule) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(l10n.deleteApplicationRuleTitle), content: Text(l10n.deleteApplicationRuleConfirmation), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.deleteRule))]));
    if (confirmed != true || !mounted) return;
    try { await ref.read(helpApplicationsRepositoryProvider).deleteAdminApplicationRule(rule['id'] as String); await _load(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ruleDeleted))); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ruleActionFailed))); }
  }

  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(margin: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.adminApplicationRules, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4), Text(l10n.adminApplicationRulesSubtitle), const SizedBox(height: 12),
      DropdownButtonFormField<String>(initialValue: _type, decoration: InputDecoration(labelText: l10n.applicationType), items: ['EDUCATION_ASSISTANCE','MEDICAL_HELP','PRATIBHA_SAMMAN'].map((type) => DropdownMenuItem(value: type, child: Text(_ruleTypeLabel(l10n, type)))).toList(growable: false), onChanged: (value) { if (value == null) return; setState(() => _type = value); _load(); }),
      const SizedBox(height: 10), Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => _editRule(), icon: const Icon(Icons.add), label: Text(l10n.addApplicationRule))), const SizedBox(height: 6),
      if (_loading) const LinearProgressIndicator(),
      if (!_loading && _rules.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(l10n.noApplicationRules)),
      if (!_loading) ..._rules.map((rule) {
        final translations = (rule['translations'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
        String english = ''; for (final item in translations) { if (item['language'] == 'en') { english = item['text']?.toString() ?? ''; break; } }
        return ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text((rule['displayOrder'] ?? '').toString())), title: Text(english), subtitle: Text((rule['isActive'] as bool? ?? false) ? l10n.ruleActive : l10n.ruleInactive), trailing: Wrap(children: [IconButton(onPressed: () => _editRule(rule), icon: const Icon(Icons.edit_outlined), tooltip: l10n.editApplicationRule), IconButton(onPressed: () => _deleteRule(rule), icon: const Icon(Icons.delete_outline), tooltip: l10n.deleteRule)]));
      }),
    ])));
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

String _windowDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatMediumDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

class _ApplicationWindowAdminPanel extends StatelessWidget {
  const _ApplicationWindowAdminPanel({
    required this.windows,
    required this.typeLabel,
    required this.formatDateTime,
    required this.onStart,
    required this.onClose,
  });

  final AsyncValue<List<ApplicationWindow>> windows;
  final String Function(String type) typeLabel;
  final String Function(DateTime value) formatDateTime;
  final Future<void> Function(String type) onStart;
  final Future<void> Function(String type) onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.applicationWindowManagement, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.applicationWindowManagementSubtitle),
            const SizedBox(height: 12),
            windows.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l10n.applicationAvailabilityLoadError),
              data: (items) {
                final knownTypes = const [
                  'EDUCATION_ASSISTANCE',
                  'MEDICAL_HELP',
                  'PRATIBHA_SAMMAN',
                ];
                return Column(
                  children: knownTypes.map((type) {
                    ApplicationWindow? window;
                    for (final item in items) {
                      if (item.type == type) {
                        window = item;
                        break;
                      }
                    }
                    final status = window?.status ?? ApplicationWindowStatus.closed;
                    final statusText = switch (status) {
                      ApplicationWindowStatus.scheduled =>
                        l10n.applicationAcceptingStartsAt(formatDateTime(window!.startsAt)),
                      ApplicationWindowStatus.open => l10n.applicationAcceptingNow,
                      ApplicationWindowStatus.closed => l10n.applicationAcceptingClosed,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(typeLabel(type), style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 3),
                          Text(statusText),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                key: ValueKey('application_window_start_$type'),
                                onPressed: () => onStart(type),
                                icon: const Icon(Icons.schedule_rounded),
                                label: Text(
                                  status == ApplicationWindowStatus.open
                                      ? l10n.applicationWindowChangeStart
                                      : l10n.startAcceptingApplications,
                                ),
                              ),
                              if (window != null && status != ApplicationWindowStatus.closed)
                                TextButton.icon(
                                  key: ValueKey('application_window_close_$type'),
                                  onPressed: () => onClose(type),
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: Text(l10n.closeApplications),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
