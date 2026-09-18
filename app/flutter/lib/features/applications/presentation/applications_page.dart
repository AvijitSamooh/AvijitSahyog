import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_settings_menu.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.homeHelpTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(l10n.homeApplicationsSubtitle),
          const SizedBox(height: 18),
          _ActionCard(
            key: const ValueKey('application_education'),
            icon: Icons.school_rounded,
            title: l10n.applyEducationHelp,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpApplicationFormPage(
                  type: 'EDUCATION_ASSISTANCE',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            key: const ValueKey('application_medical'),
            icon: Icons.medical_services_rounded,
            title: l10n.applyMedicalHelp,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpApplicationFormPage(type: 'MEDICAL_HELP'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            key: const ValueKey('application_pratibha'),
            icon: Icons.workspace_premium_rounded,
            title: l10n.applyPratibhaSamman,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpApplicationFormPage(type: 'PRATIBHA_SAMMAN'),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(l10n.applicationHistory, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          applications.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => _ApplicationHistoryError(
              onRetry: () => ref.invalidate(myHelpApplicationsProvider),
            ),
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isEmpty) Text(l10n.noApplications),
                ...items.map((item) => _ApplicationCard(application: item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationHistoryError extends StatelessWidget {
  const _ApplicationHistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(AppLocalizations.of(context)!.applicationLoadError)),
            TextButton(onPressed: onRetry, child: Text(AppLocalizations.of(context)!.retry)),
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
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _amount = TextEditingController();
  final _clarification = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _mediaIds = [];
  final List<XFile> _selectedImages = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.application;
    _name.text = existing?.applicantName ?? '';
    _mobile.text = existing?.mobileNumber ?? '';
    _email.text = existing?.email ?? '';
    _address.text = existing?.address ?? '';
    _city.text = existing?.city ?? '';
    _state.text = existing?.state ?? '';
    _pincode.text = existing?.pincode ?? '';
    if (existing?.requestedAmount != null) _amount.text = existing!.requestedAmount.toString();
    _clarification.text = existing?.clarification ?? '';
  }

  @override
  void dispose() {
    for (final controller in [_name, _mobile, _email, _address, _city, _state, _pincode, _amount, _clarification]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 10 - _mediaIds.length;
    if (remaining <= 0 || _busy) return;
    try {
      final images = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1920);
      if (images.isEmpty) return;
      await _uploadImages(images.take(remaining).toList());
    } catch (error) {
      if (mounted) _showError('Unable to select images: $error');
    }
  }

  Future<void> _takePhoto() async {
    if (_mediaIds.length >= 10 || _busy) return;
    try {
      final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 82, maxWidth: 1920);
      if (image == null) return;
      await _uploadImages([image]);
    } catch (error) {
      if (mounted) _showError('Unable to capture image: $error');
    }
  }

  Future<void> _uploadImages(List<XFile> images) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(helpApplicationsRepositoryProvider);
      for (final image in images) {
        try {
          final id = await repo.uploadImage(image.path);
          _mediaIds.add(id);
          _selectedImages.add(image);
        } catch (error) {
          if (mounted) _showError(AppLocalizations.of(context)!.imageUploadFailed + ' ' + error.toString());
          break;
        }
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 5)));
  }

  String? _required(String? value, String label) => value == null || value.trim().isEmpty ? '$label is required' : null;

  String? _mobileValidator(String? value) {
    final required = _required(value, 'Mobile number');
    if (required != null) return required;
    return RegExp(r'^\+?[0-9]{10,13}$').hasMatch(value!.trim()) ? null : 'Enter a valid mobile number';
  }

  String? _pincodeValidator(String? value) {
    final required = _required(value, 'PIN code');
    if (required != null) return required;
    return RegExp(r'^[0-9]{6}$').hasMatch(value!.trim()) ? null : 'Enter a valid 6-digit PIN code';
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
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
        await repo.create(type: widget.type, requestedAmount: amount, applicantName: _name.text, mobileNumber: _mobile.text, email: _email.text, address: _address.text, city: _city.text, state: _state.text, pincode: _pincode.text, mediaIds: _mediaIds, clarification: _clarification.text);
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
          if (widget.application?.rejectionReason != null) ...[
            Text('${l10n.rejectionReason}: ${widget.application!.rejectionReason!}'),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          TextField(controller: _clarification, minLines: 4, maxLines: 8,
            decoration: InputDecoration(labelText: l10n.clarification)),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _busy ? null : _pickImages, icon: const Icon(Icons.upload_file_rounded), label: Text(l10n.chooseImages)),
          if (_mediaIds.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('${_mediaIds.length} ${l10n.applicationEvidence}')),
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
          Text('${l10n.applicationStatus}: ${application.status}'),
          if (application.requestedAmount != null) Text('${l10n.requestedAmount}: ₹${application.requestedAmount}'),
          if (application.approvedAmount != null) Text('${l10n.approvedAmount}: ₹${application.approvedAmount}'),
          if (application.rejectionReason != null) Text('${l10n.rejectionReason}: ${application.rejectionReason!}'),
          if (application.clarification != null) Text('${l10n.clarification}: ${application.clarification!}'),
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
  const _ActionCard({super.key, required this.icon, required this.title, required this.onTap});
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
