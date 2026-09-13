import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ANALYTICS_EVENT_NAMES, AnalyticsEventName } from './analytics.constants';
export type TrackAnalyticsEventInput = { clientId: string; sessionId: string; eventName: AnalyticsEventName; screenName?: string; interactionType?: string; target?: string };
@Injectable()
export class AnalyticsService {
  constructor(private readonly prisma: PrismaService) {}
  async track(input: TrackAnalyticsEventInput) {
    if (!ANALYTICS_EVENT_NAMES.includes(input.eventName)) throw new BadRequestException('Unsupported analytics event.');
    if (!/^[a-f0-9-]{16,64}$/i.test(input.clientId) || !/^[a-f0-9-]{16,64}$/i.test(input.sessionId)) throw new BadRequestException('Invalid analytics identifiers.');
    await this.prisma.$executeRaw`INSERT INTO "AnalyticsEvent" ("clientId", "sessionId", "eventName", "screenName", "interactionType", "target") VALUES (${input.clientId}, ${input.sessionId}, ${input.eventName}, ${input.screenName ?? null}, ${input.interactionType ?? null}, ${input.target ?? null})`;
  }
}
