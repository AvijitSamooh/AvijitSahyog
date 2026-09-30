import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';

class AppNavigationBar extends StatelessWidget {
  static const int destinationCount = 5;

  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  String _screenForIndex(int index) {
    switch (index) {
      case 0:
        return AnalyticsScreens.home;
      case 1:
        return 'applications';
      case 2:
        return AnalyticsScreens.impact;
      case 3:
        return 'information';
      case 4:
        return 'profile';
      default:
        return AnalyticsScreens.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationBar(
      selectedIndex: selectedIndex.clamp(0, destinationCount - 1),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 78,
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.softSurface,
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
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.assignment_outlined),
          selectedIcon: const Icon(Icons.assignment_rounded),
          label: l10n.navApplications,
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_border_rounded),
          selectedIcon: const Icon(Icons.favorite_rounded),
          label: l10n.navImpact,
        ),
        NavigationDestination(
          icon: const Icon(Icons.info_outline_rounded),
          selectedIcon: const Icon(Icons.info_rounded),
          label: l10n.navInformation,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: l10n.navProfile,
        ),
      ],
    );
  }
}
