import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key, required this.selectedIndex, required this.onDestinationSelected});
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = [
      l10n.navHome,
      l10n.navCauses,
      l10n.navImpact,
      l10n.navSettings,
    ];

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        AnalyticsService.instance.trackInteraction(
          screenName: AnalyticsScreens.home,
          target: 'navigation_${destinations[index].toLowerCase()}',
          interactionType: AnalyticsInteractions.navigation,
        );
        onDestinationSelected(index);
      },
      destinations: [
        NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l10n.navHome),
        NavigationDestination(icon: const Icon(Icons.volunteer_activism_outlined), selectedIcon: const Icon(Icons.volunteer_activism_rounded), label: l10n.navCauses),
        NavigationDestination(icon: const Icon(Icons.auto_awesome_outlined), selectedIcon: const Icon(Icons.auto_awesome_rounded), label: l10n.navImpact),
        NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: l10n.navSettings),
      ],
    );
  }
}
