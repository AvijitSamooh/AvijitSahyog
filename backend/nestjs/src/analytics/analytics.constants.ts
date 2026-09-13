export const ANALYTICS_EVENT_NAMES = ['screen_view', 'ui_interaction', 'navigation_select'] as const;
export type AnalyticsEventName = (typeof ANALYTICS_EVENT_NAMES)[number];
