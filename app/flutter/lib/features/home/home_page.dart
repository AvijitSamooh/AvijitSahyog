import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../causes/presentation/causes_page.dart';
import '../impact/presentation/impact_page.dart';
import '../settings/settings_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/navigation/app_shell_scope.dart';
import '../../core/widgets/app_navigation_bar.dart';
import '../../core/widgets/app_settings_menu.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int get _selectedIndex => AppShellScope.of(context).navigation.index;

  void _openCauses() {
    _trackHomeTap('explore_causes');
    AppShellScope.of(context).navigation.select(1);
  }

  void _openImpact() {
    _trackHomeTap('explore_impact');
    AppShellScope.of(context).navigation.select(2);
  }

  void _trackHomeTap(String target) {
    AnalyticsService.instance.trackInteraction(
      screenName: AnalyticsScreens.home,
      target: target,
    );
  }

  String _screenForIndex(int index) {
    switch (index) {
      case 0:
        return AnalyticsScreens.home;
      case 1:
        return AnalyticsScreens.causes;
      case 2:
        return AnalyticsScreens.impact;
      case 3:
        return AnalyticsScreens.settings;
      default:
        return AnalyticsScreens.unknown;
    }
  }

  void _selectNavigation(int index) {
    final screen = _screenForIndex(index);
    AnalyticsService.instance.trackNavigation(
      destination: screen,
      screenName: AnalyticsScreens.home,
    );
    AppShellScope.of(context).navigation.select(index);
    AnalyticsService.instance.trackScreen(screen);
  }

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    final pages = [
      _HomeContent(
        onExploreCauses: _openCauses,
        onExploreImpact: _openImpact,
      ),
      const CausesPage(),
      const ImpactPage(),
      SettingsPage(onLocaleChanged: shell.onLocaleChanged, showAppBar: false),
    ];

    return AnimatedBuilder(
      animation: shell.navigation,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0
                ? AppLocalizations.of(context)!.appTitle
                : _selectedIndex == 1
                    ? AppLocalizations.of(context)!.causesTitle
                    : _selectedIndex == 2
                        ? AppLocalizations.of(context)!.impactTitle
                        : AppLocalizations.of(context)!.navSettings,
          ),
          actions: const [AppSettingsMenu()],
        ),
        body: IndexedStack(index: _selectedIndex, children: pages),
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
    required this.onExploreCauses,
    required this.onExploreImpact,
  });

  final VoidCallback onExploreCauses;
  final VoidCallback onExploreImpact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroSection(onExploreCauses: onExploreCauses),
          const SizedBox(height: 20),
          _SectionHeading(
            title: AppLocalizations.of(context)!.homeImpactTitle,
            subtitle: AppLocalizations.of(context)!.homeImpactSubtitle,
          ),
          const SizedBox(height: 12),
          _HomeImpactCard(
            onExplore: onExploreImpact,
          ),
          const SizedBox(height: 24),
          _SectionHeading(
            title: AppLocalizations.of(context)!.homeCausesTitle,
            subtitle: AppLocalizations.of(context)!.homeCausesSubtitle,
          ),
          const SizedBox(height: 12),
          _CausePreviewGrid(onExplore: onExploreCauses),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.homeCommunityTitle,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
