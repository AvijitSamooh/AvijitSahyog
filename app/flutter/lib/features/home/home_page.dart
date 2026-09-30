import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/navigation/app_shell_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_navigation_bar.dart';
import '../../core/widgets/app_settings_menu.dart';
import '../../features/applications/presentation/applications_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/causes/presentation/causes_page.dart';
import '../../features/impact/presentation/impact_page.dart';
import '../../features/settings/settings_page.dart';
import '../../l10n/app_localizations.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int get _selectedIndex => AppShellScope.of(context).navigation.index;

  void _selectNavigation(int index) {
    final destination = switch (index) {
      0 => AnalyticsScreens.home,
      1 => 'applications',
      2 => AnalyticsScreens.impact,
      3 => 'information',
      4 => 'profile',
      _ => AnalyticsScreens.unknown,
    };
    AnalyticsService.instance.trackNavigation(
      destination: destination,
      screenName: AnalyticsScreens.home,
    );
    AppShellScope.of(context).navigation.select(index);
    if (index != 0) {
      AnalyticsService.instance.trackScreen(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: AppShellScope.of(context).navigation,
      builder: (context, _) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: AppBar(
            backgroundColor: AppTheme.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 28),
                color: AppTheme.textPrimary,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => const SafeArea(child: _ReferenceMenu()),
                ),
              ),
            ),
            title: Image.asset(
              'assets/images/AvijitSamuhLogo.png',
              height: 55,
              fit: BoxFit.contain,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: l10n.navInformation,
                icon: const Icon(Icons.notifications_none_rounded, size: 27),
                color: AppTheme.textPrimary,
                onPressed: () {},
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeContent(
              onService: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CausesPage())),
              onEducation: () => _selectNavigation(1),
              onCooperation: () => _selectNavigation(2),
              onRecognition: () => _selectNavigation(1),
            ),
            const ApplicationsPage(),
            const ImpactPage(),
            SettingsPage(
              onLocaleChanged: AppShellScope.of(context).onLocaleChanged,
              showAppBar: false,
            ),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: AppNavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectNavigation,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.onService,
    required this.onEducation,
    required this.onCooperation,
    required this.onRecognition,
  });

  final VoidCallback onService;
  final VoidCallback onEducation;
  final VoidCallback onCooperation;
  final VoidCallback onRecognition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GuruBanner(),
          const SizedBox(height: 12),
          Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.brandTagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ServiceCard(
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFE96842),
                  background: const Color(0xFFFFEFE6),
                  title: l10n.homeService,
                  subtitle: l10n.homeExploreCausesSubtitle,
                  onTap: onService,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ServiceCard(
                  key: const ValueKey('home_applications'),
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF1686C7),
                  background: const Color(0xFFEAF5FD),
                  title: l10n.homeEducation,
                  subtitle: l10n.homeApplicationsSubtitle,
                  onTap: onEducation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ServiceCard(
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF269B72),
                  background: const Color(0xFFE9F7EF),
                  title: l10n.homeCooperation,
                  subtitle: l10n.homeExploreImpactSubtitle,
                  onTap: onCooperation,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ServiceCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFE09A1A),
                  background: const Color(0xFFF4ECFB),
                  title: l10n.homeRecognition,
                  subtitle: l10n.brandTagline,
                  onTap: onRecognition,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                l10n.homePurposeTitle,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Divider(color: AppTheme.secondary, thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2DB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/AvijitSamuhLogo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.homePurposeText,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuruBanner extends StatelessWidget {
  const _GuruBanner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 218,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF4D8),
                    Color(0xFFFFE8BE),
                    Color(0xFFFFF8ED),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: .13,
              child: Icon(
                Icons.account_balance_rounded,
                size: 150,
                color: AppTheme.secondary,
              ),
            ),
          ),
          Positioned(
            left: -8,
            bottom: -2,
            width: 205,
            height: 205,
            child: Image.asset(
              'assets/images/VidyasagarJi.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
            ),
          ),
          Positioned(
            right: -8,
            bottom: -2,
            width: 205,
            height: 205,
            child: Image.asset(
              'assets/images/AjitSagarJi.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomLeft,
            ),
          ),
          Positioned(
            bottom: 9,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/AvijitSamuhLogo.png',
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 126,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .78),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 24),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceMenu extends StatelessWidget {
  const _ReferenceMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(l10n.language),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(l10n.profile),
            onTap: () => Navigator.pop(context),
          ),
          const AppSettingsMenu(),
        ],
      ),
    );
  }
}
