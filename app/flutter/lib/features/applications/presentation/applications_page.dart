import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/login_page.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/help_application.dart';
import '../models/application_window.dart';
import '../models/application_rule.dart';
import '../providers/help_applications_providers.dart';

class ApplicationsPage extends ConsumerWidget {
  const ApplicationsPage({super.key, this.showAppBar = true});

  /// Standalone application routes use the standard page shell. When this
  /// page is rendered as a Home tab, HomePage already owns the shell.
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (!ref.watch(authProvider).isAuthenticated) {
      return _wrap(
        context,
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
    final applicationWindows = ref.watch(applicationWindowsProvider);
    return _wrap(
      context,
      title: Text(l10n.applicationsTitle),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myHelpApplicationsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.homeHelpTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(l10n.homeApplicationsSubtitle),
          const SizedBox(height: 18),
          _ApplicationActionCard(
            window: _findWindow(applicationWindows, 'EDUCATION_ASSISTANCE'),
            icon: Icons.school_rounded,
            title: l10n.applyEducationHelp,
            type: 'EDUCATION_ASSISTANCE',
          ),
          const SizedBox(height: 12),
          _ApplicationActionCard(
            window: _findWindow(applicationWindows, 'MEDICAL_HELP'),
            icon: Icons.medical_services_rounded,
            title: l10n.applyMedicalHelp,
            type: 'MEDICAL_HELP',
          ),
          const SizedBox(height: 12),
          _ApplicationActionCard(
            window: _findWindow(applicationWindows, 'PRATIBHA_SAMMAN'),
            icon: Icons.workspace_premium_rounded,
            title: l10n.applyPratibhaSamman,
            type: 'PRATIBHA_SAMMAN',
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
            data: (items) => items.isEmpty
                ? const _ApplicationHistoryEmpty()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map((item) => _ApplicationCard(application: item, onDelete: () => _deleteApplication(context, ref, item.id)))
                        .toList(growable: false),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _wrap(
    BuildContext context, {
    required Widget title,
    required Widget body,
  }) {
    return showAppBar
        ? AppPageScaffold(title: title, body: body)
        : body;
  }
}

  Future<void> _deleteApplication(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(l10n.deleteApplicationTitle), content: Text(l10n.deleteApplicationConfirmation), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.deleteApplication))]));
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(helpApplicationsRepositoryProvider).delete(id);
      ref.invalidate(myHelpApplicationsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationDeleted)));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteApplicationFailed)));
    }
  }

Future<void> _showWindowMessage(
  BuildContext context,
  String type,
  ApplicationWindow? window,
) async {
  final l10n = AppLocalizations.of(context)!;
  final title = _typeLabel(l10n, type);
  final message = window?.status == ApplicationWindowStatus.scheduled
      ? l10n.applicationAcceptingStartsAt(_windowDateTime(context, window!.startsAt))
      : l10n.applicationAcceptingClosed;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

class _ApplicationWindowClosedView extends StatelessWidget {
  const _ApplicationWindowClosedView({required this.window});

  final ApplicationWindow? window;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = window?.status == ApplicationWindowStatus.scheduled
        ? l10n.applicationAcceptingStartsAt(_windowDateTime(context, window!.startsAt))
        : l10n.applicationAcceptingClosed;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy_rounded, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationHistoryEmpty extends StatelessWidget {
  const _ApplicationHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          key: const ValueKey('application_history_empty'),
          children: [
            const Icon(Icons.inbox_outlined, size: 36),
            const SizedBox(height: 10),
            Text(
              l10n.noApplications,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
  final _motherName = TextEditingController();
  final _fatherName = TextEditingController();
  final _classStandard = TextEditingController();
  final _schoolInstituteName = TextEditingController();
  final _accomplishments = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _mediaIds = [];
  final List<XFile> _selectedImages = [];
  String? _certificatePhotoMediaId;
  XFile? _certificatePhoto;
  DateTime? _dob;
  bool _busy = false;
  int _uploadTotal = 0;
  int _uploadCompleted = 0;
  final Set<String> _acceptedRuleIds = <String>{};

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
    _motherName.text = existing?.motherName ?? '';
    _fatherName.text = existing?.fatherName ?? '';
    _classStandard.text = existing?.classStandard ?? '';
    _schoolInstituteName.text = existing?.schoolInstituteName ?? '';
    _accomplishments.text = existing?.accomplishments ?? '';
    _certificatePhotoMediaId = existing?.certificatePhotoMediaId;
    _dob = existing?.dateOfBirth;
  }

  @override
  void dispose() {
    for (final controller in [_name, _mobile, _email, _address, _city, _state, _pincode, _amount, _clarification, _motherName, _fatherName, _classStandard, _schoolInstituteName, _accomplishments]) {
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

  Future<void> _pickCertificatePhoto() async {
    if (_busy) return;
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (image == null) return;
      setState(() => _busy = true);
      final id = await ref.read(helpApplicationsRepositoryProvider).uploadImage(image.path);
      if (mounted) {
        setState(() {
          _certificatePhoto = image;
          _certificatePhotoMediaId = id;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(AppLocalizations.of(context)!.certificatePhotoUploadFailed);
      }
    }
  }

  Future<void> _uploadImages(List<XFile> images) async {
    if (images.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _uploadTotal = images.length;
      _uploadCompleted = 0;
    });
    try {
      final repo = ref.read(helpApplicationsRepositoryProvider);
      for (final image in images) {
        try {
          final id = await repo.uploadImage(image.path);
          _mediaIds.add(id);
          _selectedImages.add(image);
          if (mounted) {
            setState(() => _uploadCompleted++);
          }
        } catch (error) {
          if (mounted) {
            _showError(
              '${AppLocalizations.of(context)!.imageUploadFailed} ${error.toString()}',
            );
          }
          break;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _uploadTotal = 0;
          _uploadCompleted = 0;
        });
      }
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
    final currentWindow = _findWindow(ref.read(applicationWindowsProvider), widget.type);
    if (currentWindow?.isOpen != true) {
      if (mounted) {
        await _showWindowMessage(context, widget.type, currentWindow);
      }
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final isSamman = widget.type == 'PRATIBHA_SAMMAN';
    final rules = ref.read(applicationRulesProvider((type: widget.type, language: Localizations.localeOf(context).languageCode))).valueOrNull ?? const <ApplicationRule>[];
    if (_acceptedRuleIds.length != rules.length || rules.any((rule) => !_acceptedRuleIds.contains(rule.id))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationRulesRequired)));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_mediaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.imagesRequired)));
      return;
    }
    if (widget.type == 'PRATIBHA_SAMMAN' && _certificatePhotoMediaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.certificatePhotoRequired)));
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
        await repo.create(type: widget.type, requestedAmount: amount, applicantName: _name.text, mobileNumber: _mobile.text, email: _email.text, address: _address.text, city: _city.text, state: _state.text, pincode: _pincode.text, motherName: isSamman ? _motherName.text : null, fatherName: isSamman ? _fatherName.text : null, dateOfBirth: isSamman ? _dob : null, classStandard: isSamman ? _classStandard.text : null, schoolInstituteName: isSamman ? _schoolInstituteName.text : null, accomplishments: isSamman ? _accomplishments.text : null, certificatePhotoMediaId: isSamman ? _certificatePhotoMediaId : null, mediaIds: _mediaIds, acceptedRuleIds: _acceptedRuleIds.toList(growable: false), clarification: _clarification.text);
      } else {
        await repo.resubmit(id: widget.application!.id, clarification: _clarification.text, mediaIds: _mediaIds, acceptedRuleIds: _acceptedRuleIds.toList(growable: false), requestedAmount: amount, motherName: isSamman ? _motherName.text : null, fatherName: isSamman ? _fatherName.text : null, dateOfBirth: isSamman ? _dob : null, classStandard: isSamman ? _classStandard.text : null, schoolInstituteName: isSamman ? _schoolInstituteName.text : null, accomplishments: isSamman ? _accomplishments.text : null, certificatePhotoMediaId: isSamman ? _certificatePhotoMediaId : null);
      }
      ref.invalidate(myHelpApplicationsProvider);
      if (mounted) {
        await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) => AlertDialog(title: Text(l10n.applicationSubmissionSuccessTitle), content: Text(l10n.applicationSubmitted), actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.close))]));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationSubmissionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSamman = widget.type == 'PRATIBHA_SAMMAN';
    final windows = ref.watch(applicationWindowsProvider);
    final rules = ref.watch(applicationRulesProvider((type: widget.type, language: Localizations.localeOf(context).languageCode)));
    if (windows.isLoading) {
      return AppPageScaffold(
        title: Text(_typeLabel(l10n, widget.type)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (windows.hasError) {
      return AppPageScaffold(
        title: Text(_typeLabel(l10n, widget.type)),
        body: Center(child: Text(l10n.applicationAvailabilityLoadError)),
      );
    }
    final window = _findWindow(windows, widget.type);
    if (window?.isOpen != true) {
      return AppPageScaffold(
        title: Text(_typeLabel(l10n, widget.type)),
        body: _ApplicationWindowClosedView(window: window),
      );
    }
    final activeWindow = window!;
    if (rules.isLoading) {
      return AppPageScaffold(
        title: Text(_typeLabel(l10n, widget.type)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (rules.hasError) {
      return AppPageScaffold(
        title: Text(_typeLabel(l10n, widget.type)),
        body: Center(child: Text(l10n.applicationRulesLoadError)),
      );
    }
    final applicationRules = rules.valueOrNull ?? const <ApplicationRule>[];
    return AppPageScaffold(
      title: Text(_typeLabel(l10n, widget.type)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            if (applicationRules.isNotEmpty) ...[
              Text(l10n.applicationRulesTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(l10n.applicationRulesSubtitle),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: applicationRules.asMap().entries.map((entry) {
                      final rule = entry.value;
                      return CheckboxListTile(
                        value: _acceptedRuleIds.contains(rule.id),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text('\${entry.key + 1}. \${rule.text}'),
                        onChanged: _busy ? null : (checked) {
                          setState(() {
                            if (checked == true) {
                              _acceptedRuleIds.add(rule.id);
                            } else {
                              _acceptedRuleIds.remove(rule.id);
                            }
                          });
                        },
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (isSamman && (activeWindow.registrationEndsAt != null || activeWindow.eventAt != null)) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.importantDates, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('\${l10n.formAvailableDate}: \${_windowDateTime(context, activeWindow.startsAt)}'),
                      if (activeWindow.registrationEndsAt != null)
                        Text('\${l10n.registrationLastDate}: \${_windowDateTime(context, activeWindow.registrationEndsAt!)}'),
                      if (activeWindow.eventAt != null)
                        Text('\${l10n.eventDate}: \${_windowDateTime(context, activeWindow.eventAt!)}'),
                      const SizedBox(height: 6),
                      Text(l10n.organisationManagedBy, style: Theme.of(context).textTheme.bodySmall),
                      Text(l10n.organisationRegistrationNumber, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(l10n.applicantDetails, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('application_applicant_name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.fullNameRequired, prefixIcon: const Icon(Icons.person_outline)),
              validator: (v) => _required(v, l10n.fullNameRequired),
            ),
            TextFormField(
              key: const ValueKey('application_mobile'),
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: isSamman ? l10n.mobileWhatsappRequired : l10n.mobileNumberRequired, prefixIcon: const Icon(Icons.phone_outlined)),
              validator: _mobileValidator,
            ),
            TextFormField(
              key: const ValueKey('application_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailOptional, prefixIcon: const Icon(Icons.email_outlined)),
            ),
            TextFormField(
              key: const ValueKey('application_address'),
              controller: _address,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.addressRequired, prefixIcon: const Icon(Icons.home_outlined)),
              validator: (v) => _required(v, l10n.addressRequired),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TextFormField(
                  key: const ValueKey('application_city'),
                  controller: _city,
                  decoration: InputDecoration(labelText: l10n.cityRequired),
                  validator: (v) => _required(v, l10n.cityRequired),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  key: const ValueKey('application_state'),
                  controller: _state,
                  decoration: InputDecoration(labelText: l10n.stateRequired),
                  validator: (v) => _required(v, l10n.stateRequired),
                )),
              ],
            ),
            TextFormField(
              key: const ValueKey('application_pincode'),
              controller: _pincode,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.pincodeRequired, prefixIcon: const Icon(Icons.location_on_outlined)),
              validator: _pincodeValidator,
            ),
            if (isSamman) ...[
              const SizedBox(height: 20),
              Text(l10n.pratibhaStudentDetails, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('pratibha_mother_name'),
                controller: _motherName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.motherNameRequired, prefixIcon: const Icon(Icons.family_restroom)),
                validator: (v) => _required(v, l10n.motherNameRequired),
              ),
              TextFormField(
                key: const ValueKey('pratibha_father_name'),
                controller: _fatherName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.fatherNameRequired, prefixIcon: const Icon(Icons.family_restroom)),
                validator: (v) => _required(v, l10n.fatherNameRequired),
              ),
              FormField<DateTime>(
                key: const ValueKey('pratibha_date_of_birth'),
                validator: (_) => _dob == null ? l10n.dateOfBirthRequired : null,
                builder: (field) => InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.dateOfBirthRequired,
                    prefixIcon: const Icon(Icons.cake_outlined),
                    errorText: field.errorText,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_dob == null ? l10n.selectDateOfBirth : _windowDateTime(context, _dob!)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: _busy ? null : () async {
                      final now = DateTime.now();
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _dob ?? DateTime(now.year - 10, now.month, now.day),
                        firstDate: DateTime(1980),
                        lastDate: now,
                        helpText: l10n.dateOfBirthRequired,
                      );
                      if (selected != null) {
                        setState(() => _dob = selected);
                        field.didChange(selected);
                      }
                    },
                  ),
                ),
              ),
              TextFormField(
                key: const ValueKey('pratibha_class_standard'),
                controller: _classStandard,
                decoration: InputDecoration(labelText: l10n.classStandardRequired, prefixIcon: const Icon(Icons.school_outlined)),
                validator: (v) => _required(v, l10n.classStandardRequired),
              ),
              TextFormField(
                key: const ValueKey('pratibha_school_institute'),
                controller: _schoolInstituteName,
                decoration: InputDecoration(labelText: l10n.schoolInstituteRequired, prefixIcon: const Icon(Icons.account_balance_outlined)),
                validator: (v) => _required(v, l10n.schoolInstituteRequired),
              ),
              const SizedBox(height: 8),
              Text(l10n.certificatePhotoTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(l10n.certificatePhotoHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('pratibha_certificate_photo'),
                onPressed: _busy ? null : _pickCertificatePhoto,
                icon: const Icon(Icons.badge_outlined),
                label: Text(_certificatePhotoMediaId == null ? l10n.selectCertificatePhoto : l10n.certificatePhotoSelected),
              ),
              if (_certificatePhoto != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(_certificatePhoto!.path), height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              TextFormField(
                key: const ValueKey('pratibha_accomplishments'),
                controller: _accomplishments,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(labelText: l10n.otherAccomplishmentsOptional, alignLabelWithHint: true, prefixIcon: const Icon(Icons.emoji_events_outlined)),
              ),
            ],

            const SizedBox(height: 20),
            if (!isSamman)
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.requestedAmount, prefixText: '₹'),
              ),
            if (widget.application?.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Text('${l10n.rejectionReason}: ${widget.application!.rejectionReason!}'),
            ],
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('application_explanation'),
              controller: _clarification,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: isSamman ? l10n.achievementDetails : l10n.explainNeed,
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              validator: (v) => _required(v, isSamman ? l10n.achievementDetails : l10n.explainNeed),
            ),
            const SizedBox(height: 20),
            Text(l10n.supportingDocuments, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.supportingDocumentsHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(
                  key: const ValueKey('application_gallery'),
                  onPressed: _busy || _mediaIds.length >= 10 ? null : _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.gallery),
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  key: const ValueKey('application_camera'),
                  onPressed: _busy || _mediaIds.length >= 10 ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(l10n.camera),
                )),
              ],
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(_selectedImages[index].path), width: 92, height: 92, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            if (_mediaIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.uploadedCount(_mediaIds.length)),
              ),
            if (_busy && _uploadTotal > 0)
              ApplicationUploadProgress(
                label: l10n.uploadingImage,
                completed: _uploadCompleted,
                total: _uploadTotal,
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('application_submit'),
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _busy ? l10n.uploadingImage : l10n.submitApplication,
              ),
            ),
          ],
        ),
      ),

    );
  }
}

class ApplicationUploadProgress extends StatelessWidget {
  const ApplicationUploadProgress({
    super.key,
    required this.label,
    required this.completed,
    required this.total,
  });

  final String label;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : completed / total;
    return Padding(
      key: const ValueKey('application_upload_progress'),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('$label $completed/$total')),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, minHeight: 5),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.onDelete});
  final HelpApplication application;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canResubmit = application.status == 'REJECTED' || application.status == 'CLARIFICATION_REQUIRED';
    final canDelete = application.status != 'APPROVED_FOR_DONATION' && application.status != 'CONSIDERED_FOR_SAMMAN';
    return Card(
      child: ListTile(
        title: Text(_typeLabel(l10n, application.type)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${l10n.applicationStatus}: ${_statusLabel(l10n, application.status)}'),
          if (application.requestedAmount != null) Text('${l10n.requestedAmount}: ₹${application.requestedAmount}'),
          if (application.approvedAmount != null) Text('${l10n.approvedAmount}: ₹${application.approvedAmount}'),
          if (application.rejectionReason != null) Text('${l10n.rejectionReason}: ${application.rejectionReason!}'),
          if (application.clarification != null) Text('${l10n.clarification}: ${application.clarification!}'),
        ]),
        isThreeLine: true,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (canResubmit) IconButton(tooltip: l10n.resubmitApplication, icon: const Icon(Icons.refresh_rounded), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HelpApplicationFormPage(type: application.type, application: application)))),
          if (canDelete) IconButton(key: ValueKey('application_delete_${application.id}'), tooltip: l10n.deleteApplication, icon: const Icon(Icons.delete_outline_rounded), onPressed: onDelete),
        ]),
      ),
    );
  }
}

String _applicationActionKey(String type) {
  switch (type) {
    case 'EDUCATION_ASSISTANCE':
      return 'application_education';
    case 'MEDICAL_HELP':
      return 'application_medical';
    case 'PRATIBHA_SAMMAN':
      return 'application_pratibha';
    default:
      return 'application_$type';
  }
}

ApplicationWindow? _findWindow(
  AsyncValue<List<ApplicationWindow>> windows,
  String type,
) {
  return windows.maybeWhen(
    data: (items) {
      for (final item in items) {
        if (item.type == type) return item;
      }
      return null;
    },
    orElse: () => null,
  );
}

String _windowDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatMediumDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

class _ApplicationActionCard extends ConsumerWidget {
  const _ApplicationActionCard({
    required this.window,
    required this.icon,
    required this.title,
    required this.type,
  });

  final ApplicationWindow? window;
  final IconData icon;
  final String title;
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = window?.status ?? ApplicationWindowStatus.closed;
    final baseStatus = switch (status) {
      ApplicationWindowStatus.scheduled =>
        l10n.applicationAcceptingStartsAt(_windowDateTime(context, window!.startsAt)),
      ApplicationWindowStatus.open => l10n.applicationAcceptingNow,
      ApplicationWindowStatus.closed => l10n.applicationAcceptingClosed,
    };
    final activeWindow = window;
    final subtitle = type == 'PRATIBHA_SAMMAN' && activeWindow != null
        ? [
            baseStatus,
            if (activeWindow.registrationEndsAt != null)
              '\${l10n.registrationLastDate}: \${_windowDateTime(context, activeWindow.registrationEndsAt!)}',
            if (activeWindow.eventAt != null)
              '\${l10n.eventDate}: \${_windowDateTime(context, activeWindow.eventAt!)}',
          ].join('\n')
        : baseStatus;

    return _ActionCard(
      key: ValueKey(_applicationActionKey(type)),
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () async {
        if (window?.isOpen == true) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HelpApplicationFormPage(type: type)),
          );
          ref.invalidate(applicationWindowsProvider);
          return;
        }

        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(subtitle),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({super.key, required this.icon, required this.title, this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
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
