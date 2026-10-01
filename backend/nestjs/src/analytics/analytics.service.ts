import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ANALYTICS_EVENT_NAMES, AnalyticsEventName } from './analytics.constants';

export const MAX_ANALYTICS_BATCH_SIZE = 50;

export type TrackAnalyticsEventInput = {
  clientId: string;
  sessionId: string;
  eventName: AnalyticsEventName;
  screenName?: string;
  interactionType?: string;
  target?: string;
  city?: string;
  language?: string;
  deviceType?: string;
};

@Injectable()
export class AnalyticsService {
  constructor(private readonly prisma: PrismaService) {}

  async track(input: TrackAnalyticsEventInput) {
    await this.trackBatch([input]);
  }

  async trackBatch(inputs: TrackAnalyticsEventInput[]) {
    if (inputs.length === 0) return;
    if (inputs.length > MAX_ANALYTICS_BATCH_SIZE) {
      throw new BadRequestException(`Analytics batch cannot exceed ${MAX_ANALYTICS_BATCH_SIZE} events.`);
    }

    for (const input of inputs) {
      this.validate(input);
    }

    await this.prisma.analyticsEvent.createMany({
      data: inputs.map((input) => ({
        clientId: input.clientId,
        sessionId: input.sessionId,
        eventName: input.eventName,
        screenName: input.screenName ?? null,
        interactionType: input.interactionType ?? null,
        target: input.target ?? null,
        city: input.city ?? null,
        language: input.language ?? null,
        deviceType: input.deviceType ?? null,
      })),
    });
  }

  private validate(input: TrackAnalyticsEventInput) {
    if (!ANALYTICS_EVENT_NAMES.includes(input.eventName)) {
      throw new BadRequestException('Unsupported analytics event.');
    }
    if (!/^[a-f0-9-]{16,64}$/i.test(input.clientId) || !/^[a-f0-9-]{16,64}$/i.test(input.sessionId)) {
      throw new BadRequestException('Invalid analytics identifiers.');
    }
  }
}
