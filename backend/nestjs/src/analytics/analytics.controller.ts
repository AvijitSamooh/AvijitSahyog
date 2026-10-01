import { Body, Controller, Post } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { ANALYTICS_EVENT_NAMES, AnalyticsEventName } from './analytics.constants';
import { MAX_ANALYTICS_BATCH_SIZE } from './analytics.service';
import type { TrackAnalyticsEventInput } from './analytics.service';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Post('events')
  async track(@Body() body: TrackAnalyticsEventInput) {
    const input = this.normalize(body);
    if (!input) return { accepted: false };
    await this.analyticsService.track(input);
    return { accepted: true };
  }

  @Post('events/batch')
  async trackBatch(@Body() body: { events?: unknown }) {
    if (!Array.isArray(body.events) || body.events.length === 0 || body.events.length > MAX_ANALYTICS_BATCH_SIZE) {
      return { accepted: false, acceptedCount: 0 };
    }

    const events = body.events
      .map((item) => this.normalize(item))
      .filter((item): item is TrackAnalyticsEventInput => item !== null);

    if (events.length !== body.events.length) {
      return { accepted: false, acceptedCount: 0 };
    }

    await this.analyticsService.trackBatch(events);
    return { accepted: true, acceptedCount: events.length };
  }

  private normalize(body: unknown): TrackAnalyticsEventInput | null {
    if (!body || typeof body !== 'object') return null;
    const item = body as Record<string, unknown>;
    const { clientId, sessionId, eventName } = item;
    if (
      typeof clientId !== 'string' ||
      typeof sessionId !== 'string' ||
      typeof eventName !== 'string' ||
      !ANALYTICS_EVENT_NAMES.includes(eventName as AnalyticsEventName)
    ) {
      return null;
    }
    return {
      clientId,
      sessionId,
      eventName: eventName as AnalyticsEventName,
      screenName: typeof item.screenName === 'string' ? item.screenName : undefined,
      interactionType: typeof item.interactionType === 'string' ? item.interactionType : undefined,
      target: typeof item.target === 'string' ? item.target : undefined,
      city: typeof item.city === 'string' ? item.city : undefined,
      language: typeof item.language === 'string' ? item.language : undefined,
      deviceType: typeof item.deviceType === 'string' ? item.deviceType : undefined,
    };
  }
}
