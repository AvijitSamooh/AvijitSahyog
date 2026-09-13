export const ANALYTICS_EVENT_NAMES = [
  'screen_view',
  'ui_interaction',
  'navigation_select',
] as const;

export type AnalyticsEventName = (typeof ANALYTICS_EVENT_NAMES)[number];

export const ANALYTICS_SCREEN_VIEWS = new Set(['screen_view']);
export const ANALYTICS_INTERACTIONS = new Set([
  'ui_interaction',
  'navigation_select',
]);
