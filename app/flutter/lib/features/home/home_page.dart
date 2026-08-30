import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../causes/presentation/causes_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _openCauses() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CausesPage()),
    );
  }

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
      const _ImpactPlaceholder(),
      SettingsPage(onLocaleChanged: widget.onLocaleChanged),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text('Avijit Sahyog'),
              actions: [
                IconButton(
                  tooltip: 'Language',
                  icon: const Icon(Icons.language_rounded),
                  onPressed: _showLanguageSelector,
                ),
              ],
            )
          : null,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism_rounded),
            label: 'Causes',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Impact',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _HeroSection(onExploreCauses: onExploreCauses),
        const SizedBox(height: 24),
        Text('Welcome to Avijit Sahyog', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(
          'A simple way to come together, support meaningful causes, and create a lasting impact.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _ActionCard(
          icon: Icons.volunteer_activism_rounded,
          title: 'Explore Causes',
          subtitle: 'Discover the causes you can support and the work happening behind them.',
          action: 'Explore',
          onTap: onExploreCauses,
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.auto_awesome_rounded,
          title: 'See Our Impact',
          subtitle: 'Meet the people and communities whose lives have been supported.',
          action: 'Explore',
          onTap: onExploreImpact,
        ),
        const SizedBox(height: 28),
        const _GivingQuote(),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onExploreCauses});

  final VoidCallback onExploreCauses;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 390),
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
              'assets/images/ajit_sagar_ji.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                const SizedBox(
                  width: 210,
                  child: Text(
                    'Together, we can make compassion reach further.',
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
                    'Support the causes that matter. See the impact your contribution creates.',
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
                  label: const Text('Explore Causes'),
                ),
              ],
            ),
          ),
        ],
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: Color(0xFF6E1A14), size: 34),
          SizedBox(height: 8),
          Text(
            'The value of a gift is not measured by what leaves your hand, but by the difference it makes in someone’s life.',
            style: TextStyle(
              color: Color(0xFF39271C),
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '— The spirit of selfless giving',
            style: TextStyle(color: Color(0xFF6B4F36)),
          ),
        ],
      ),
    );
  }
}

class _ImpactPlaceholder extends StatelessWidget {
  const _ImpactPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 56,
              color: Color(0xFF6E1A14),
            ),
            const SizedBox(height: 16),
            Text('Our Impact', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'In the next phase, this space will let you explore beneficiaries, their stories, and the impact created across every cause.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.currentLocale});

  final String currentLocale;

  @override
  Widget build(BuildContext context) {
    final options = const [
      ('English', 'en'),
      ('हिंदी', 'hi'),
      ('मराठी', 'mr'),
      ('ગુજરાતી', 'gu'),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF8ED),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
