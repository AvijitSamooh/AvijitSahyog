import { AnalyticsService } from './analytics.service';

describe('AnalyticsService', () => {
  const prisma = {
    $executeRaw: jest.fn(),
  } as any;
  const service = new AnalyticsService(prisma);

  beforeEach(() => jest.clearAllMocks());

  it('stores a canonical analytics event', async () => {
    prisma.$executeRaw.mockResolvedValue(1);

    await service.track({
      clientId: '0123456789abcdef0123456789abcdef',
      sessionId: 'fedcba9876543210fedcba9876543210',
      eventName: 'ui_interaction',
      screenName: 'home',
      interactionType: 'tap',
      target: 'explore_causes',
    });

    expect(prisma.$executeRaw).toHaveBeenCalledTimes(1);
  });

  it('rejects malformed analytics identifiers', async () => {
    await expect(
      service.track({
        clientId: 'not-valid',
        sessionId: 'fedcba9876543210fedcba9876543210',
        eventName: 'screen_view',
        screenName: 'home',
      }),
    ).rejects.toThrow('Invalid analytics identifiers.');
  });
});
