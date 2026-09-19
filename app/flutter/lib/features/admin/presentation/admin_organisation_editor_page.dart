import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';
import '../../../l10n/app_localizations.dart';

import '../models/admin_organisation.dart';
import '../providers/admin_causes_providers.dart';
import 'admin_media_section.dart';
import '../providers/admin_organisations_providers.dart';

class AdminOrganisationEditorPage extends ConsumerStatefulWidget {
  const AdminOrganisationEditorPage({super.key, this.organisation});
  final AdminOrganisation? organisation;

  @override
  ConsumerState<AdminOrganisationEditorPage> createState() =>
      _AdminOrganisationEditorPageState();
}

class _AdminOrganisationEditorPageState
    extends ConsumerState<AdminOrganisationEditorPage> {
  static const _languages = ['en', 'hi', 'mr', 'gu'];
  late final TextEditingController _website;
  late final TextEditingController _phone;
  late final TextEditingController _mobileNumber;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _country;
  late final TextEditingController _order;
  late final Map<String, TextEditingController> _names;
  late final Map<String, TextEditingController> _descriptions;
  late Set<String> _causeIds;
  bool _saving = false;
  List<PendingAdminMedia> _pendingMedia = [];

  bool get _editing => widget.organisation != null;

  @override
  void initState() {
    super.initState();
    final organisation = widget.organisation;
    _website = TextEditingController(text: organisation?.websiteUrl ?? '');
    _phone = TextEditingController(text: organisation?.phone ?? '');
    _mobileNumber = TextEditingController(text: organisation?.mobileNumber ?? '');
    _email = TextEditingController(text: organisation?.email ?? '');
    _address = TextEditingController(text: organisation?.address ?? '');
    _city = TextEditingController(text: organisation?.city ?? '');
    _state = TextEditingController(text: organisation?.state ?? '');
    _country = TextEditingController(text: organisation?.country ?? 'IN');
    _order = TextEditingController(text: '${organisation?.displayOrder ?? 0}');
    final translations = {
      for (final item in organisation?.translations ?? []) item.languageCode: item,
    };
    _names = {
      for (final language in _languages)
        language: TextEditingController(text: translations[language]?.name ?? ''),
    };
    _descriptions = {
      for (final language in _languages)
        language: TextEditingController(
          text: translations[language]?.description ?? '',
        ),
    };
    _causeIds = {...?organisation?.causeIds};
  }

  @override
  void dispose() {
    for (final controller in [
      _website, _phone, _mobileNumber, _email, _address, _city, _state, _country, _order,
      ..._names.values, ..._descriptions.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final translations = _languages
        .where((language) => _names[language]!.text.trim().isNotEmpty)
        .map((language) => {
              'languageCode': language,
              'name': _names[language]!.text.trim(),
              if (_descriptions[language]!.text.trim().isNotEmpty)
                'description': _descriptions[language]!.text.trim(),
            })
        .toList();
    if (translations.isEmpty) {
      _error(l10n.adminAddAtLeastOneTranslation);
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'websiteUrl': _website.text.trim(),
        'phone': _phone.text.trim(),
        'mobileNumber': _mobileNumber.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'country': _country.text.trim(),
        'displayOrder': int.tryParse(_order.text) ?? 0,
        'translations': translations,
      };

      final repository = ref.read(adminOrganisationsRepositoryProvider);
      if (_editing) {
        await repository.update(widget.organisation!.id, payload);
        await repository.updateCauses(widget.organisation!.id, _causeIds.toList());
        if (mounted) Navigator.of(context).pop();
      } else {
        final created = await repository.create(payload);
        try {
          await repository.updateCauses(created.id, _causeIds.toList());
          await _attachPendingMedia(created.id);
        } catch (error) {
          if (mounted) {
            _error(l10n.adminOrganisationCreatedPartialFailure(error.toString()));
            Navigator.of(context).pop();
          }
          return;
        }
        if (mounted) Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) _error(l10n.adminOrganisationSaveFailed(error.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _attachPendingMedia(String entityId) async {
    final api = ref.read(adminApiClientProvider);
    for (final item in _pendingMedia) {
      final uploaded = await api.uploadAdminImage(item.file.path);
      await api.attachAdminEntityMedia('organisations', entityId, {'mediaId': uploaded['id'], 'purpose': item.purpose, 'isPrimary': item.purpose == 'LOGO', 'displayOrder': 0});
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _languageLabel(AppLocalizations l10n, String language) {
    switch (language) {
      case 'en':
        return l10n.languageEnglish;
      case 'hi':
        return l10n.languageHindi;
      case 'mr':
        return l10n.languageMarathi;
      case 'gu':
        return l10n.languageGujarati;
      default:
        return language.toUpperCase();
    }
  }


  @override
  Widget build(BuildContext context) {
    final causes = ref.watch(adminCausesProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: Text(_editing ? l10n.adminEditOrganisation : l10n.adminCreateOrganisation),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          TextField(controller: _website, decoration: InputDecoration(labelText: l10n.adminOrganisationWebsite)),
          TextField(controller: _phone, decoration: InputDecoration(labelText: l10n.adminOrganisationPhone)),
          TextField(key: const ValueKey('admin_organisation_mobile_number'), controller: _mobileNumber, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l10n.adminOrganisationMobileNumber, hintText: l10n.adminOrganisationMobileNumberHint)),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: l10n.adminOrganisationEmail)),
          TextField(controller: _address, decoration: InputDecoration(labelText: l10n.adminOrganisationAddress)),
          Row(children: [
            Expanded(child: TextField(controller: _city, decoration: InputDecoration(labelText: l10n.adminOrganisationCity))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _state, decoration: InputDecoration(labelText: l10n.adminOrganisationState))),
          ]),
          TextField(controller: _country, decoration: InputDecoration(labelText: l10n.adminOrganisationCountry)),
          TextField(controller: _order, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.adminOrganisationDisplayOrder)),
          const SizedBox(height: 24),
          Text(l10n.adminSupportedCauses, style: Theme.of(context).textTheme.titleLarge),
          causes.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text(l10n.adminOrganisationLoadCausesFailed),
            data: (items) {
              final leafCauses = items.expand((cause) => cause.children.isEmpty ? [cause] : cause.children).toList(growable: false);
              return Column(
                children: leafCauses.map((cause) => CheckboxListTile(
                  value: _causeIds.contains(cause.id),
                  title: Text(cause.displayName(languageCode)),
                  onChanged: (selected) => setState(() {
                    if (selected ?? false) {
                      _causeIds.add(cause.id);
                    } else {
                      _causeIds.remove(cause.id);
                    }
                  }),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          AdminMediaSection(
            api: _editing ? ref.read(adminApiClientProvider) : null,
            entity: _editing ? 'organisations' : null,
            entityId: _editing ? widget.organisation!.id : null,
            primaryPurpose: 'LOGO',
            title: l10n.adminOrganisationImages,
            onPendingChanged: (items) => _pendingMedia = items,
          ),
          const SizedBox(height: 24),
          Text(l10n.adminTranslations, style: Theme.of(context).textTheme.titleLarge),
          for (final language in _languages) Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, child: Text(_languageLabel(l10n, language))),
                TextField(key: ValueKey('admin_organisation_name_$language'), controller: _names[language], decoration: InputDecoration(labelText: l10n.adminTranslationName)),
                TextField(controller: _descriptions[language], minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: l10n.adminTranslationDescription)),
              ]),
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
              key: const ValueKey('admin_save_organisation'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.adminOrganisationSaving : (_editing ? l10n.adminSaveChanges : l10n.adminCreateOrganisation)),
            ),
          ),
        ),
      ),
    );
  }
}
