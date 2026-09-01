import { AdminDashboardService } from './admin-dashboard.service';

describe('AdminDashboardService', () => {
  const prisma = {
    cause: { count: jest.fn() },
    organisation: { count: jest.fn() },
    beneficiary: { count: jest.fn() },
  } as any;
  const service = new AdminDashboardService(prisma);

  beforeEach(() => jest.clearAllMocks());

  it('returns total, active and inactive counts for every managed entity', async () => {
    prisma.cause.count.mockResolvedValueOnce(10).mockResolvedValueOnce(8);
    prisma.organisation.count.mockResolvedValueOnce(6).mockResolvedValueOnce(5);
    prisma.beneficiary.count.mockResolvedValueOnce(20).mockResolvedValueOnce(17);

    await expect(service.getSummary()).resolves.toEqual({
      causes: { total: 10, active: 8, inactive: 2 },
      organisations: { total: 6, active: 5, inactive: 1 },
      beneficiaries: { total: 20, active: 17, inactive: 3 },
    });
  });
});
