import { BadRequestException } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';

describe('AnalyticsService', () => {
  it('writes a batch with one database operation', async () => {
    const prisma = {
      analyticsEvent: { createMany: jest.fn().mockResolvedValue({ count: 3 }) },
    };
    const service = new AnalyticsService(prisma as never);

    await service.trackBatch([
      { clientId: 'a'.repeat(32), sessionId: 'b'.repeat(32), eventName: 'screen_view', screenName: 'home' },
      { clientId: 'a'.repeat(32), sessionId: 'b'.repeat(32), eventName: 'ui_interaction', screenName: 'home', target: 'donate' },
      { clientId: 'a'.repeat(32), sessionId: 'b'.repeat(32), eventName: 'navigation_select', screenName: 'home', target: 'causes' },
    ]);

    expect(prisma.analyticsEvent.createMany).toHaveBeenCalledTimes(1);
    expect(prisma.analyticsEvent.createMany).toHaveBeenCalledWith({
      data: expect.arrayContaining([
        expect.objectContaining({ eventName: 'screen_view' }),
        expect.objectContaining({ eventName: 'ui_interaction' }),
        expect.objectContaining({ eventName: 'navigation_select' }),
      ]),
    });
  });

  it('rejects invalid identifiers before touching the database', async () => {
    const prisma = { analyticsEvent: { createMany: jest.fn() } };
    const service = new AnalyticsService(prisma as never);

    await expect(service.trackBatch([{
      clientId: 'bad',
      sessionId: 'b'.repeat(32),
      eventName: 'screen_view',
    }])).rejects.toBeInstanceOf(BadRequestException);

    expect(prisma.analyticsEvent.createMany).not.toHaveBeenCalled();
  });

  it('rejects batches above the safety limit', async () => {
    const prisma = { analyticsEvent: { createMany: jest.fn() } };
    const service = new AnalyticsService(prisma as never);
    const events = Array.from({ length: 51 }, () => ({
      clientId: 'a'.repeat(32),
      sessionId: 'b'.repeat(32),
      eventName: 'screen_view' as const,
    }));

    await expect(service.trackBatch(events)).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.analyticsEvent.createMany).not.toHaveBeenCalled();
  });
});
