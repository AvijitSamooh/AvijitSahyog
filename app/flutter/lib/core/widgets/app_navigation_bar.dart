import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key, required this.selectedIndex, required this.onDestinationSelected});
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  String _screenForIndex(int index) {
    switch (index) {
      case 0:
        return AnalyticsScreens.home;
      case 1:
        return AnalyticsScreens.causes;
      case 2:
        return AnalyticsScreens.impact;
            default:
        return AnalyticsScreens.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationBar(
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        final destination = _screenForIndex(index);
        AnalyticsService.instance.trackInteraction(
          screenName: _screenForIndex(selectedIndex),
          target: destination,
          interactionType: AnalyticsInteractions.navigation,
        );
        onDestinationSelected(index);
      },
      destinations: [
        NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l10n.navHome),
        NavigationDestination(icon: const Icon(Icons.volunteer_activism_outlined), selectedIcon: const Icon(Icons.volunteer_activism_rounded), label: l10n.navCauses),
        NavigationDestination(icon: const Icon(Icons.auto_awesome_outlined), selectedIcon: const Icon(Icons.auto_awesome_rounded), label: l10n.navImpact),
      ],
    );
  }
}
