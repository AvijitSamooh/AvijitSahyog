import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/app_shell_scope.dart';

enum _SettingsAction { language, account }

class AppSettingsMenu extends ConsumerWidget {
  const AppSettingsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authenticated = ref.watch(authProvider).isAuthenticated;
    return PopupMenuButton<_SettingsAction>(
      key: const ValueKey('app_settings_menu'),
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: l10n.navSettings,
      onSelected: (action) async {
        if (action == _SettingsAction.language) {
          final selected = await _showLanguageSelector(context);
          if (selected != null && context.mounted) {
            AppShellScope.of(context).onLocaleChanged(selected);
          }
          return;
        }
        if (!context.mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => authenticated ? const ProfilePage() : const LoginPage(),
        ));
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: _SettingsAction.language, child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.language_rounded), title: Text(l10n.language))),
        PopupMenuItem(value: _SettingsAction.account, child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(authenticated ? Icons.account_circle_rounded : Icons.login_rounded), title: Text(authenticated ? l10n.profile : l10n.login))),
      ],
    );
  }

  Future<Locale?> _showLanguageSelector(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final options = [(l10n.languageEnglish, 'en'), (l10n.languageHindi, 'hi'), (l10n.languageMarathi, 'mr'), (l10n.languageGujarati, 'gu')];
    return showModalBottomSheet<Locale>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => ListTile(
            leading: Icon(option.$2 == current ? Icons.check_circle_rounded : Icons.language_rounded),
            title: Text(option.$1),
            onTap: () => Navigator.of(context).pop(Locale(option.$2)),
          )).toList(growable: false),
        ),
      ),
    );
  }
}
