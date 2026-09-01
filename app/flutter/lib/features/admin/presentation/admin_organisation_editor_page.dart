import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_cause.dart';
import '../models/admin_organisation.dart';
import '../providers/admin_causes_providers.dart';
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
  late final TextEditingController _slug;
  late final TextEditingController _website;
  late final TextEditingController _phone;
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

  bool get _editing => widget.organisation != null;

  @override
  void initState() {
    super.initState();
    final organisation = widget.organisation;
    _slug = TextEditingController(text: organisation?.slug ?? '');
    _website = TextEditingController(text: organisation?.websiteUrl ?? '');
    _phone = TextEditingController(text: organisation?.phone ?? '');
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
      _slug, _website, _phone, _email, _address, _city, _state, _country, _order,
      ..._names.values, ..._descriptions.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_slug.text.trim().isEmpty) {
      _error('Slug is required.');
      return;
    }
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
      _error('Add at least one translation.');
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'slug': _slug.text.trim(),
        'websiteUrl': _website.text.trim(),
        'phone': _phone.text.trim(),
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
      } else {
        final created = await repository.create(payload);
        await repository.updateCauses(created.id, _causeIds.toList());
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _error('Unable to save organisation.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final causes = ref.watch(adminCausesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit organisation' : 'Create organisation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          TextField(key: const ValueKey('admin_organisation_slug'), controller: _slug, decoration: const InputDecoration(labelText: 'Slug')),
          TextField(controller: _website, decoration: const InputDecoration(labelText: 'Website')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
          Row(children: [
            Expanded(child: TextField(controller: _city, decoration: const InputDecoration(labelText: 'City'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _state, decoration: const InputDecoration(labelText: 'State'))),
          ]),
          TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
          TextField(controller: _order, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Display order')),
          const SizedBox(height: 24),
          Text('Supported causes', style: Theme.of(context).textTheme.titleLarge),
          causes.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => const Text('Unable to load causes.'),
            data: (items) => Column(
              children: items.map((cause) => CheckboxListTile(
                value: _causeIds.contains(cause.id),
                title: Text(cause.displayName),
                onChanged: (selected) => setState(() {
                  if (selected ?? false) {
                    _causeIds.add(cause.id);
                  } else {
                    _causeIds.remove(cause.id);
                  }
                }),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Translations', style: Theme.of(context).textTheme.titleLarge),
          for (final language in _languages) Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, child: Text(language.toUpperCase())),
                TextField(key: ValueKey('admin_organisation_name_$language'), controller: _names[language], decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: _descriptions[language], minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
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
              child: Text(_saving ? 'Saving...' : (_editing ? 'Save changes' : 'Create organisation')),
            ),
          ),
        ),
      ),
    );
  }
}
