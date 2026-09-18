import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../causes/presentation/causes_page.dart';
import '../impact/presentation/impact_page.dart';
import '../applications/presentation/applications_page.dart';
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
    AnalyticsService.instance.trackInteraction(
      screenName: AnalyticsScreens.home,
      target: 'explore_causes',
    );
    AppShellScope.of(context).navigation.select(1);
  }

  void _openApplications() {
    AnalyticsService.instance.trackInteraction(
      screenName: AnalyticsScreens.home,
      target: 'applications',
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ApplicationsPage()),
    );
  }

  void _openImpact() {
    AnalyticsService.instance.trackInteraction(
      screenName: AnalyticsScreens.home,
      target: 'explore_impact',
    );
    AppShellScope.of(context).navigation.select(2);
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
    if (index != _selectedIndex) {
      AnalyticsService.instance.trackScreen(screen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    final pages = [
      _HomeContent(
        onExploreCauses: _openCauses,
        onExploreImpact: _openImpact,
        onApplications: _openApplications,
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
    required this.onApplications,
  });

  final VoidCallback onExploreCauses;
  final VoidCallback onExploreImpact;
  final VoidCallback onApplications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _HeroSection(onExploreCauses: onExploreCauses),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.homeWelcome, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context)!.homeIntro,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _ActionCard(
          icon: Icons.volunteer_activism_rounded,
          title: AppLocalizations.of(context)!.homeExploreCauses,
          subtitle: AppLocalizations.of(context)!.homeExploreCausesSubtitle,
          action: AppLocalizations.of(context)!.explore,
          onTap: onExploreCauses,
        ),
        const SizedBox(height: 14),
        _ActionCard(
          key: const ValueKey('home_applications'),
          icon: Icons.assignment_rounded,
          title: AppLocalizations.of(context)!.applicationsTitle,
          subtitle: AppLocalizations.of(context)!.homeApplicationsSubtitle,
          action: AppLocalizations.of(context)!.applyNow,
          onTap: onApplications,
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.auto_awesome_rounded,
          title: AppLocalizations.of(context)!.homeImpact,
          subtitle: AppLocalizations.of(context)!.homeExploreImpactSubtitle,
          action: 'Explore',
          onTap: onExploreImpact,
        ),
        const SizedBox(height: 28),
        const _GivingQuote(),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onExploreCauses});

  final VoidCallback onExploreCauses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 590,
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E1A14), Color(0xFF3E0C08)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
        child: Stack(
          children: [
          Positioned(
            right: -35,
            top: -55,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5A623).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 8,
            bottom: 0,
            child: Image.asset(
              'assets/images/AjitSagarJi.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.self_improvement_rounded, size: 140, color: Color(0xFFF5A623)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.self_improvement_rounded,
                  color: Color(0xFFF5A623),
                  size: 30,
                ),
                const Spacer(),
                SizedBox(
                  width: 210,
                  child: Text(
                    AppLocalizations.of(context)!.homeHeroTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 205,
                  child: Text(
                    AppLocalizations.of(context)!.homeHeroSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: const Color(0xFF4C120D),
                  ),
                  onPressed: onExploreCauses,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(AppLocalizations.of(context)!.homeExploreCauses),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8C9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF6E1A14)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      '$action →',
                      style: const TextStyle(
                        color: Color(0xFF6E1A14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GivingQuote extends StatelessWidget {
  const _GivingQuote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE8C9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: Color(0xFF6E1A14), size: 34),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.givingQuote,
            style: TextStyle(
              color: Color(0xFF39271C),
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.givingQuoteAttribution,
            style: TextStyle(color: Color(0xFF6B4F36)),
          ),
        ],
      ),
    );
  }
}
