import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../causes/presentation/causes_page.dart';
import '../impact/presentation/impact_page.dart';
import '../settings/settings_page.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/login_page.dart';
import '../auth/presentation/profile_page.dart';
import '../auth/providers/auth_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  void _openCauses() => setState(() => _selectedIndex = 1);

  void _showLanguageSelector() async {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final selectedLocale = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(currentLocale: currentLocale),
    );

    if (selectedLocale != null) {
      widget.onLocaleChanged(selectedLocale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeContent(
        onExploreCauses: _openCauses,
        onExploreImpact: () => setState(() => _selectedIndex = 2),
      ),
      const CausesPage(),
      const ImpactPage(),
      SettingsPage(onLocaleChanged: widget.onLocaleChanged, showAppBar: false),
    ];

    return Scaffold(
      appBar: _selectedIndex == 3
          ? null
          : AppBar(
              title: Text(_selectedIndex == 0
                  ? AppLocalizations.of(context)!.appTitle
                  : _selectedIndex == 1
                      ? AppLocalizations.of(context)!.causesTitle
                      : AppLocalizations.of(context)!.impactTitle),
              actions: [
                IconButton(
                  key: const ValueKey('auth_entry'),
                  tooltip: ref.watch(authProvider).isAuthenticated
                      ? AppLocalizations.of(context)!.profile
                      : AppLocalizations.of(context)!.login,
                  icon: Icon(ref.watch(authProvider).isAuthenticated
                      ? Icons.account_circle_rounded
                      : Icons.login_rounded),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ref.read(authProvider).isAuthenticated
                          ? const ProfilePage()
                          : const LoginPage(),
                    ));
                  },
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.language,
                  icon: const Icon(Icons.language_rounded),
                  onPressed: _showLanguageSelector,
                ),
              ],
            ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppLocalizations.of(context)!.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism_rounded),
            label: AppLocalizations.of(context)!.navCauses,
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: AppLocalizations.of(context)!.navImpact,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: AppLocalizations.of(context)!.navSettings,
          ),
        ],
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



class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.currentLocale});

  final String currentLocale;

  @override
  Widget build(BuildContext context) {
    final options = [
      (AppLocalizations.of(context)!.languageEnglish, 'en'),
      (AppLocalizations.of(context)!.languageHindi, 'hi'),
      (AppLocalizations.of(context)!.languageMarathi, 'mr'),
      (AppLocalizations.of(context)!.languageGujarati, 'gu'),
    ];

    return Material(
      color: const Color(0xFFFFF8ED),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              final selected = option.$2 == currentLocale;
              return ListTile(
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: const Color(0xFF6E1A14),
                ),
                title: Text(option.$1),
                onTap: () => Navigator.pop(context, Locale(option.$2)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
