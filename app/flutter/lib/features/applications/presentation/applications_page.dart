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
    if (remaining <= 0) return;
    try {
      final images = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1920);
      if (images.isEmpty) return;
      await _uploadImages(images.take(remaining).toList());
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to select/upload images: $error')));
    }
  }

  Future<void> _takePhoto() async {
    if (_mediaIds.length >= 10) return;
    try {
      final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 82, maxWidth: 1920);
      if (image == null) return;
      await _uploadImages([image]);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to capture/upload image: $error')));
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
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $error')));
          break;
        }
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        await repo.create(
          type: widget.type,
          requestedAmount: amount,
          applicantName: _name.text,
          mobileNumber: _mobile.text,
          email: _email.text,
          address: _address.text,
          city: _city.text,
          state: _state.text,
          pincode: _pincode.text,
          mediaIds: _mediaIds,
          clarification: _clarification.text,
        );
      } else {
        await repo.resubmit(id: widget.application!.id, clarification: _clarification.text, mediaIds: _mediaIds, requestedAmount: amount);
      }
      ref.invalidate(myHelpApplicationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationSubmitted)));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to submit application: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return label + ' is required';
    return null;
  }

  String? _mobileValidator(String? value) {
    final error = _required(value, 'Mobile number');
    if (error != null) return error;
    if (!RegExp(r'^\+?[0-9]{10,13}
    final l10n = AppLocalizations.of(context)!;
    final isSamman = widget.type == 'PRATIBHA_SAMMAN';
    return AppPageScaffold(
      title: Text(_typeLabel(l10n, widget.type)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text('Applicant details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => _required(v, 'Full name')),
            TextFormField(controller: _mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number *', prefixIcon: Icon(Icons.phone_outlined)), validator: _mobileValidator),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (optional)', prefixIcon: Icon(Icons.email_outlined)),
            TextFormField(controller: _address, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Address *', prefixIcon: Icon(Icons.home_outlined)), validator: (v) => _required(v, 'Address')),
            Row(children: [
              Expanded(child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City *'), validator: (v) => _required(v, 'City'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _state, decoration: const InputDecoration(labelText: 'State *'), validator: (v) => _required(v, 'State'))),
            ]),
            TextFormField(controller: _pincode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN code *', prefixIcon: Icon(Icons.location_on_outlined)), validator: (v) {
              final error = _required(v, 'PIN code');
              if (error != null) return error;
              return RegExp(r'^[0-9]{6}
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
).hasMatch(value!.trim())) return 'Enter a valid mobile number';
    return null;
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
).hasMatch(v!.trim()) ? null : 'Enter a valid 6-digit PIN code';
            }),
            const SizedBox(height: 20),
            if (!isSamman)
              TextFormField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.requestedAmount, prefixText: '₹')),
            if (widget.application?.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Text('${l10n.rejectionReason}: ${widget.application!.rejectionReason!}'),
            ],
            const SizedBox(height: 16),
            TextFormField(controller: _clarification, minLines: 4, maxLines: 8, decoration: InputDecoration(labelText: isSamman ? 'Achievement details' : 'Explain your need', alignLabelWithHint: true, prefixIcon: const Icon(Icons.description_outlined)), validator: (v) => _required(v, isSamman ? 'Achievement details' : 'Explanation')),
            const SizedBox(height: 18),
            Text('Supporting documents / images *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _busy || _mediaIds.length >= 10 ? null : _pickImages, icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: _busy || _mediaIds.length >= 10 ? null : _takePhoto, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Camera'))),
            ]),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_selectedImages[index].path), width: 92, height: 92, fit: BoxFit.cover)),
                  ),
                ),
              ),
            if (_mediaIds.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_mediaIds.length.toString() + '/10 uploaded')),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _busy ? null : _submit, icon: const Icon(Icons.send_rounded), label: Text(_busy ? l10n.uploadingImage : l10n.submitApplication)),
          ],
        ),
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
).hasMatch(value!.trim())) return 'Enter a valid mobile number';
    return null;
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
