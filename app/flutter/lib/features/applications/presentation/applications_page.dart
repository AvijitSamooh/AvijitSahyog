import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/login_page.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/help_application.dart';
import '../providers/help_applications_providers.dart';

class ApplicationsPage extends ConsumerWidget {
  const ApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (!ref.watch(authProvider).isAuthenticated) {
      return AppPageScaffold(
        title: Text(l10n.applicationsTitle),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            child: Text(l10n.loginToApply),
          ),
        ),
      );
    }

    final applications = ref.watch(myHelpApplicationsProvider);
    return AppPageScaffold(
      title: Text(l10n.applicationsTitle),
      body: applications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.applicationLoadError)),
        data: (items) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ActionCard(icon: Icons.school_rounded, title: l10n.applyEducationHelp,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpApplicationFormPage(type: 'EDUCATION_ASSISTANCE')))),
            const SizedBox(height: 12),
            _ActionCard(icon: Icons.medical_services_rounded, title: l10n.applyMedicalHelp,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpApplicationFormPage(type: 'MEDICAL_HELP')))),
            const SizedBox(height: 12),
            _ActionCard(icon: Icons.workspace_premium_rounded, title: l10n.applyPratibhaSamman,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpApplicationFormPage(type: 'PRATIBHA_SAMMAN')))),
            const SizedBox(height: 28),
            Text(l10n.applicationHistory, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (items.isEmpty) Text(l10n.noApplications),
            ...items.map((item) => _ApplicationCard(application: item)),
          ],
        ),
      ),
    );
  }
}

class HelpApplicationFormPage extends ConsumerStatefulWidget {
  const HelpApplicationFormPage({super.key, required this.type, this.application});
  final String type;
  final HelpApplication? application;

  @override
  ConsumerState<HelpApplicationFormPage> createState() => _HelpApplicationFormPageState();
}

class _HelpApplicationFormPageState extends ConsumerState<HelpApplicationFormPage> {
  final _amount = TextEditingController();
  final _clarification = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _mediaIds = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.application;
    if (existing?.requestedAmount != null) _amount.text = existing!.requestedAmount.toString();
    if (existing?.clarification != null) _clarification.text = existing!.clarification!;
  }

  @override
  void dispose() {
    _amount.dispose();
    _clarification.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1920);
    if (images.isEmpty) return;
    setState(() => _busy = true);
    try {
      for (final image in images.take(10 - _mediaIds.length)) {
        final id = await ref.read(helpApplicationsRepositoryProvider).uploadImage(image.path);
        _mediaIds.add(id);
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_mediaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.imagesRequired)));
      return;
    }
    double? amount;
    if (widget.type != 'PRATIBHA_SAMMAN') {
      amount = double.tryParse(_amount.text.trim());
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestedAmountRequired)));
        return;
      }
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(helpApplicationsRepositoryProvider);
      if (widget.application == null) {
        await repo.create(type: widget.type, requestedAmount: amount, mediaIds: _mediaIds, clarification: _clarification.text);
      } else {
        await repo.resubmit(id: widget.application!.id, clarification: _clarification.text, mediaIds: _mediaIds, requestedAmount: amount);
      }
      ref.invalidate(myHelpApplicationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationSubmitted)));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSamman = widget.type == 'PRATIBHA_SAMMAN';
    return AppPageScaffold(
      title: Text(_typeLabel(l10n, widget.type)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!isSamman)
            TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.requestedAmount, prefixText: '₹')),
          const SizedBox(height: 16),
          TextField(controller: _clarification, minLines: 4, maxLines: 8,
            decoration: InputDecoration(labelText: l10n.clarification)),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _busy ? null : _pickImages, icon: const Icon(Icons.upload_file_rounded), label: Text(l10n.chooseImages)),
          if (_mediaIds.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(_mediaIds.length.toString() + ' ' + l10n.applicationEvidence)),
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? l10n.uploadingImage : l10n.submitApplication)),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});
  final HelpApplication application;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canResubmit = application.status == 'REJECTED' || application.status == 'CLARIFICATION_REQUIRED';
    return Card(
      child: ListTile(
        title: Text(_typeLabel(l10n, application.type)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.applicationStatus + ': ' + application.status),
          if (application.requestedAmount != null) Text(l10n.requestedAmount + ': ₹' + application.requestedAmount.toString()),
          if (application.approvedAmount != null) Text(l10n.approvedAmount + ': ₹' + application.approvedAmount.toString()),
          if (application.rejectionReason != null) Text(l10n.rejectionReason + ': ' + application.rejectionReason!),
          if (application.clarification != null) Text(l10n.clarification + ': ' + application.clarification!),
        ]),
        isThreeLine: true,
        trailing: canResubmit ? IconButton(
          tooltip: l10n.resubmitApplication,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => HelpApplicationFormPage(type: application.type, application: application))),
        ) : null,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap));
}

String _typeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'MEDICAL_HELP': return l10n.medicalHelp;
    case 'PRATIBHA_SAMMAN': return l10n.pratibhaSamman;
    default: return l10n.educationHelp;
  }
}
