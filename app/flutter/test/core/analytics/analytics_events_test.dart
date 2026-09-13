import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/analytics/analytics_events.dart';

void main() {
  test('analytics event names remain stable', () {
    expect(AnalyticsEvents.screenView, 'screen_view');
    expect(AnalyticsEvents.interaction, 'ui_interaction');
    expect(AnalyticsEvents.navigationSelect, 'navigation_select');
  });

  test('analytics screen names remain stable', () {
    expect(AnalyticsScreens.home, 'home');
    expect(AnalyticsScreens.causes, 'causes');
    expect(AnalyticsScreens.impact, 'impact');
    expect(AnalyticsScreens.settings, 'settings');
  });

  test('analytics parameter names remain stable', () {
    expect(AnalyticsParameters.screenName, 'screen_name');
    expect(AnalyticsParameters.interactionType, 'interaction_type');
    expect(AnalyticsParameters.target, 'target');
    expect(AnalyticsParameters.destination, 'destination');
  });
}
