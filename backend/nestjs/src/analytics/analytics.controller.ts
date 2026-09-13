import { Body, Controller, Post } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { ANALYTICS_EVENT_NAMES, AnalyticsEventName } from './analytics.constants';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Post('events')
  async track(@Body() body: {
    clientId?: unknown;
    sessionId?: unknown;
    eventName?: unknown;
    screenName?: unknown;
    interactionType?: unknown;
    target?: unknown;
    city?: unknown;
    language?: unknown;
    deviceType?: unknown;
  }) {
    const { clientId, sessionId, eventName } = body;
    if (typeof clientId !== 'string' || typeof sessionId !== 'string' || typeof eventName !== 'string' || !ANALYTICS_EVENT_NAMES.includes(eventName as AnalyticsEventName)) {
      return { accepted: false };
    }
    await this.analyticsService.track({
      clientId,
      sessionId,
      eventName: eventName as AnalyticsEventName,
      screenName: typeof body.screenName === 'string' ? body.screenName : undefined,
      interactionType: typeof body.interactionType === 'string' ? body.interactionType : undefined,
      target: typeof body.target === 'string' ? body.target : undefined,
      city: typeof body.city === 'string' ? body.city : undefined,
      language: typeof body.language === 'string' ? body.language : undefined,
      deviceType: typeof body.deviceType === 'string' ? body.deviceType : undefined,
    });
    return { accepted: true };
  }
}
