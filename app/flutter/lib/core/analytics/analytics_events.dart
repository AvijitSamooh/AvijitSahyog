/// Canonical analytics event names and parameter keys.
///
/// Keep this taxonomy stable so dashboards and reports do not depend on
/// screen-specific implementation details.
abstract final class AnalyticsEvents {
  static const screenView = 'screen_view';
  static const interaction = 'ui_interaction';
  static const navigationSelect = 'navigation_select';
}

abstract final class AnalyticsParameters {
  static const screenName = 'screen_name';
  static const screenClass = 'screen_class';
  static const interactionType = 'interaction_type';
  static const target = 'target';
  static const destination = 'destination';
}

abstract final class AnalyticsScreens {
  static const home = 'home';
  static const causes = 'causes';
  static const impact = 'impact';
  static const settings = 'settings';
  static const admin = 'admin';
  static const unknown = 'unknown';
}

abstract final class AnalyticsInteractions {
  static const tap = 'tap';
  static const navigation = 'navigation';
}
