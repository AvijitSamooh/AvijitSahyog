import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_settings_menu.dart';

import '../models/admin_cause.dart';
import '../providers/admin_causes_providers.dart';

class AdminCauseEditorPage extends ConsumerStatefulWidget {
  const AdminCauseEditorPage({super.key, this.cause});

  final AdminCause? cause;

  @override
  ConsumerState<AdminCauseEditorPage> createState() =>
      _AdminCauseEditorPageState();
}

class _AdminCauseEditorPageState extends ConsumerState<AdminCauseEditorPage> {
  static const _languages = ['en', 'hi', 'mr', 'gu'];

  late final TextEditingController _slugController;
  late final TextEditingController _orderController;
  late final Map<String, TextEditingController> _nameControllers;
  late final Map<String, TextEditingController> _descriptionControllers;
  bool _isSaving = false;

  bool get _isEditing => widget.cause != null;

  @override
  void initState() {
    super.initState();
    _slugController = TextEditingController(text: widget.cause?.slug ?? '');
    _orderController = TextEditingController(
      text: '${widget.cause?.displayOrder ?? 0}',
    );

    final translations = {
      for (final translation in widget.cause?.translations ?? [])
        translation.languageCode: translation,
    };

    _nameControllers = {
      for (final language in _languages)
        language: TextEditingController(
          text: translations[language]?.name ?? '',
        ),
    };
    _descriptionControllers = {
      for (final language in _languages)
        language: TextEditingController(
          text: translations[language]?.description ?? '',
        ),
    };
  }

  @override
  void dispose() {
    _slugController.dispose();
    _orderController.dispose();
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final slug = _slugController.text.trim();
    if (slug.isEmpty) {
      _showError('Slug is required.');
      return;
    }

    final translations = <Map<String, dynamic>>[];
    for (final language in _languages) {
      final name = _nameControllers[language]!.text.trim();
      final description = _descriptionControllers[language]!.text.trim();
      if (name.isNotEmpty) {
        translations.add({
          'languageCode': language,
          'name': name,
          if (description.isNotEmpty) 'description': description,
        });
      }
    }

    if (translations.isEmpty) {
      _showError('Add at least one language translation.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'slug': slug,
        'displayOrder': int.tryParse(_orderController.text) ?? 0,
        'translations': translations,
      };

      if (_isEditing) {
        await ref
            .read(adminCausesRepositoryProvider)
            .updateCause(widget.cause!.id, payload);
      } else {
        await ref.read(adminCausesRepositoryProvider).createCause(payload);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        _showError('Unable to save cause. Please review the data and retry.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: Text(_isEditing ? 'Edit cause' : 'Create cause'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            TextField(
              key: const ValueKey('admin_cause_slug'),
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug',
                helperText: 'Unique URL-friendly identifier',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Display order'),
            ),
            const SizedBox(height: 28),
            Text(
              'Translations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final language in _languages)
              _TranslationSection(
                language: language,
                nameController: _nameControllers[language]!,
                descriptionController: _descriptionControllers[language]!,
              ),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('admin_save_cause'),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Create cause'),
            ),
          ),
        ),
      ),
    );
  }
}

class _TranslationSection extends StatelessWidget {
  const _TranslationSection({
    required this.language,
    required this.nameController,
    required this.descriptionController,
  });

  final String language;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(language.toUpperCase()),
            const SizedBox(height: 12),
            TextField(
              key: ValueKey('admin_cause_name_$language'),
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
    );
  }
}
