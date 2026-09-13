import { AdminDashboardService } from './admin-dashboard.service';

describe('AdminDashboardService', () => {
  const prisma = { cause: { count: jest.fn() }, organisation: { count: jest.fn() }, beneficiary: { count: jest.fn() }, $queryRaw: jest.fn() } as any;
  const service = new AdminDashboardService(prisma);
  beforeEach(() => jest.clearAllMocks());

  it('returns total, active and inactive counts for every managed entity', async () => {
    prisma.cause.count.mockResolvedValueOnce(10).mockResolvedValueOnce(8); prisma.organisation.count.mockResolvedValueOnce(6).mockResolvedValueOnce(5); prisma.beneficiary.count.mockResolvedValueOnce(20).mockResolvedValueOnce(17);
    await expect(service.getSummary()).resolves.toEqual({ causes: { total: 10, active: 8, inactive: 2 }, organisations: { total: 6, active: 5, inactive: 1 }, beneficiaries: { total: 20, active: 17, inactive: 3 } });
  });

  it('maps analytics metrics and the daily engagement trend', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ dau: BigInt(3), wau: BigInt(8), mau: BigInt(12), newUsers: BigInt(7), returningUsers: BigInt(5) }]).mockResolvedValueOnce([{ sessions: BigInt(20), screenViews: BigInt(80), interactions: BigInt(40), navigationEvents: BigInt(25) }]).mockResolvedValueOnce([{ day: new Date('2026-09-12T00:00:00.000Z'), activeUsers: BigInt(4), sessions: BigInt(6), screenViews: BigInt(18), interactions: BigInt(9) }]);
    await expect(service.getAnalytics()).resolves.toEqual({ periodDays: 30, dau: 3, wau: 8, mau: 12, newUsers: 7, returningUsers: 5, sessions: 20, screenViews: 80, interactions: 40, navigationEvents: 25, engagementTrend: [{ date: '2026-09-12', activeUsers: 4, sessions: 6, screenViews: 18, interactions: 9 }] });
  });
});
