import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../models/admin_beneficiary.dart';
import '../models/admin_cause.dart';
import '../models/admin_organisation.dart';
import '../providers/admin_beneficiaries_providers.dart';
import '../providers/admin_causes_providers.dart';
import 'admin_media_section.dart';
import '../providers/admin_organisations_providers.dart';

class AdminBeneficiaryEditorPage extends ConsumerStatefulWidget {
  const AdminBeneficiaryEditorPage({super.key, this.beneficiary});
  final AdminBeneficiary? beneficiary;

  @override
  ConsumerState<AdminBeneficiaryEditorPage> createState() =>
      _AdminBeneficiaryEditorPageState();
}

class _AdminBeneficiaryEditorPageState
    extends ConsumerState<AdminBeneficiaryEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _story;
  late final TextEditingController _year;
  late final TextEditingController _amount;
  late final TextEditingController _displayOrder;
  String? _causeId;
  String? _organisationId;
  bool _saving = false;
  List<PendingAdminMedia> _pendingMedia = [];

  bool get _editing => widget.beneficiary != null;

  @override
  void initState() {
    super.initState();
    final item = widget.beneficiary;
    _name = TextEditingController(text: item?.name ?? '');
    _story = TextEditingController(text: item?.story ?? '');
    _year = TextEditingController(text: '${item?.supportedYear ?? DateTime.now().year}');
    _amount = TextEditingController(text: '${item?.contributionAmount ?? ''}');
    _displayOrder = TextEditingController(text: '${item?.displayOrder ?? 0}');
    _causeId = item?.causeId;
    _organisationId = item?.organisationId;
  }

  @override
  void dispose() {
    for (final controller in [_name, _story, _year, _amount, _displayOrder]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final year = int.tryParse(_year.text);
    final amount = num.tryParse(_amount.text);
    if (name.isEmpty || year == null || amount == null || amount <= 0 || _causeId == null) {
      _error('Name, valid year, contribution amount and cause are required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'name': name,
        'supportedYear': year,
        'contributionAmount': amount,
        'causeId': _causeId,
        'organisationId': _organisationId,
        'displayOrder': int.tryParse(_displayOrder.text) ?? 0,
        if (_story.text.trim().isNotEmpty) 'story': _story.text.trim(),
      };
      final repository = ref.read(adminBeneficiariesRepositoryProvider);
      if (_editing) {
        await repository.update(widget.beneficiary!.id, payload);
      } else {
        final created = await repository.create(payload);
        await _attachPendingMedia(created.id);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _error('Unable to save beneficiary.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _attachPendingMedia(String entityId) async {
    final api = ref.read(adminApiClientProvider);
    for (final item in _pendingMedia) {
      final uploaded = await api.uploadAdminImage(item.file.path);
      await api.attachAdminEntityMedia('beneficiaries', entityId, {'mediaId': uploaded['id'], 'purpose': item.purpose, 'isPrimary': item.purpose == 'PROFILE', 'displayOrder': 0});
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final causes = ref.watch(adminCausesProvider);
    final organisations = ref.watch(adminOrganisationsProvider);
    return AppPageScaffold(
      title: Text(_editing ? 'Edit beneficiary' : 'Create beneficiary'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          TextField(key: const ValueKey('admin_beneficiary_name'), controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _story, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Impact story')),
          Row(children: [
            Expanded(child: TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Supported year'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Contribution amount'))),
          ]),
          TextField(controller: _displayOrder, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Display order')),
          const SizedBox(height: 16),
          causes.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => const Text('Unable to load causes.'),
            data: (items) => DropdownButtonFormField<String>(
              key: const ValueKey('admin_beneficiary_cause'),
              initialValue: items.any((item) => item.id == _causeId) ? _causeId : null,
              decoration: const InputDecoration(labelText: 'Cause'),
              items: items.map((AdminCause item) => DropdownMenuItem(value: item.id, child: Text(item.displayName))).toList(),
              onChanged: (value) => setState(() => _causeId = value),
            ),
          ),
          const SizedBox(height: 24),
          AdminMediaSection(
            api: _editing ? ref.read(adminApiClientProvider) : null,
            entity: _editing ? 'beneficiaries' : null,
            entityId: _editing ? widget.beneficiary!.id : null,
            primaryPurpose: 'PROFILE',
            title: 'Beneficiary images',
            onPendingChanged: (items) => _pendingMedia = items,
          ),
          const SizedBox(height: 12),
          organisations.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => const Text('Unable to load organisations.'),
            data: (items) => DropdownButtonFormField<String>(
              initialValue: items.any((item) => item.id == _organisationId) ? _organisationId : null,
              decoration: const InputDecoration(labelText: 'Organisation (optional)'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('No organisation')),
                ...items.map((AdminOrganisation item) => DropdownMenuItem(value: item.id, child: Text(item.displayName))),
              ],
              onChanged: (value) => setState(() => _organisationId = value),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('admin_save_beneficiary'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : (_editing ? 'Save changes' : 'Create beneficiary')),
            ),
          ),
        ),
      ),
    );
  }
}
