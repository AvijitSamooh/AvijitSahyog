import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/admin/presentation/admin_portal_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/app_shell_scope.dart';
import 'app_navigation_bar.dart';

enum _SettingsAction { language, account, adminPortal, logout }

/// Standard page actions used by every application AppBar.
///
/// New pages should use [AppPageScaffold] (or [AppPageAppBar]) so language,
/// account and logout actions remain consistent without page-specific wiring.
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
        switch (action) {
          case _SettingsAction.language:
            final selected = await _showLanguageSelector(context);
            if (selected != null && context.mounted) {
              AppShellScope.of(context).onLocaleChanged(selected);
            }
            return;
          case _SettingsAction.account:
            if (!context.mounted) return;
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => authenticated ? const ProfilePage() : const LoginPage(),
            ));
            return;
          case _SettingsAction.adminPortal:
            if (!context.mounted) return;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPortalPage()));
            return;
          case _SettingsAction.logout:
            await ref.read(authProvider.notifier).signOut();
            if (!context.mounted) return;
            Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _SettingsAction.language,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language_rounded),
            title: Text(l10n.language),
          ),
        ),
        PopupMenuItem(
          value: _SettingsAction.account,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(authenticated
                ? Icons.account_circle_rounded
                : Icons.login_rounded),
            title: Text(authenticated ? l10n.profile : l10n.login),
          ),
        ),
        if (authenticated && ref.watch(authProvider).user?.isAdmin == true)
          PopupMenuItem(
            key: const ValueKey('app_settings_admin_portal'),
            value: _SettingsAction.adminPortal,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.admin_panel_settings_rounded),
              title: Text(l10n.adminPortal),
            ),
          ),
        if (authenticated)
          PopupMenuItem(
            value: _SettingsAction.logout,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded),
              title: Text(l10n.logout),
            ),
          ),
      ],
    );
  }

  Future<Locale?> _showLanguageSelector(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (l10n.languageEnglish, 'en'),
      (l10n.languageHindi, 'hi'),
      (l10n.languageMarathi, 'mr'),
      (l10n.languageGujarati, 'gu'),
    ];
    return showModalBottomSheet<Locale>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((option) => ListTile(
                    leading: Icon(option.$2 == current
                        ? Icons.check_circle_rounded
                        : Icons.language_rounded),
                    title: Text(option.$1),
                    onTap: () =>
                        Navigator.of(context).pop(Locale(option.$2)),
                  ))
              .toList(growable: false),
        ),
      ),
    );
  }
}

class AppPageAppBar extends AppBar {
  AppPageAppBar({
    super.key,
    super.title,
    super.leading,
    super.automaticallyImplyLeading,
    super.bottom,
    super.elevation,
    super.scrolledUnderElevation,
  }) : super(actions: const [AppSettingsMenu()]);
}

class AppPageScaffold extends Scaffold {
  AppPageScaffold({
    super.key,
    required Widget title,
    super.body,
    super.floatingActionButton,
    super.floatingActionButtonLocation,
    super.bottomNavigationBar,
    super.bottomSheet,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? appBarBottom,
    double? appBarElevation,
    double? appBarScrolledUnderElevation,
  }) : super(
          appBar: AppPageAppBar(
            title: title,
            automaticallyImplyLeading: automaticallyImplyLeading,
            bottom: appBarBottom,
            elevation: appBarElevation,
            scrolledUnderElevation: appBarScrolledUnderElevation,
          ),
          bottomNavigationBar: bottomNavigationBar ?? const _SharedBottomNavigationBar(),
        );
}

class _SharedBottomNavigationBar extends StatelessWidget {
  const _SharedBottomNavigationBar();

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    return AnimatedBuilder(
      animation: shell.navigation,
      builder: (context, _) => AppNavigationBar(
        selectedIndex: shell.navigation.index,
        onDestinationSelected: (index) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          shell.navigation.select(index);
        },
      ),
    );
  }
}
