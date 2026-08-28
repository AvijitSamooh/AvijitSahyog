import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.onLocaleChanged,
  });

  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.language,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _languageTile(
            context,
            label: l10n.languageEnglish,
            locale: const Locale('en'),
          ),
          _languageTile(
            context,
            label: l10n.languageHindi,
            locale: const Locale('hi'),
          ),
          _languageTile(
            context,
            label: l10n.languageMarathi,
            locale: const Locale('mr'),
          ),
          _languageTile(
            context,
            label: l10n.languageGujarati,
            locale: const Locale('gu'),
          ),
        ],
      ),
    );
  }

  Widget _languageTile(
    BuildContext context, {
    required String label,
    required Locale locale,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          onLocaleChanged(locale);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
