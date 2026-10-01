import 'package:flutter/material.dart';

import '../../core/widgets/app_settings_menu.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.onLocaleChanged,
    this.showAppBar = true,
  });

  final ValueChanged<Locale> onLocaleChanged;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final currentLocale = Localizations.localeOf(context).languageCode;
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(l10n.language, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.65,
              children: [
                _languageTile(context, label: l10n.languageEnglish, locale: const Locale('en'), selected: currentLocale == 'en'),
                _languageTile(context, label: l10n.languageHindi, locale: const Locale('hi'), selected: currentLocale == 'hi'),
                _languageTile(context, label: l10n.languageMarathi, locale: const Locale('mr'), selected: currentLocale == 'mr'),
                _languageTile(context, label: l10n.languageGujarati, locale: const Locale('gu'), selected: currentLocale == 'gu'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_balance_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeOrganisationTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.homeOrganisationDetails),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return showAppBar
        ? AppPageScaffold(title: Text(l10n.language), body: content)
        : content;
  }

  Widget _languageTile(
    BuildContext context, {
    required String label,
    required Locale locale,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          onLocaleChanged(locale);
          if (showAppBar) Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
