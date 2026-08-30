import { NotFoundException } from '@nestjs/common';
import { BeneficiariesService } from './beneficiaries.service';

describe('BeneficiariesService', () => {
  const prisma = {
    beneficiary: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
    },
  } as any;

  const service = new BeneficiariesService(prisma);

  const record = {
    id: 'beneficiary-1',
    name: 'Rahul Kumar',
    photoUrl: null,
    story: 'Educational support story',
    supportedYear: 2025,
    contributionAmount: { toString: () => '25000' },
    cause: { id: 'cause-1', slug: 'education' },
    organisation: { id: 'org-1', slug: 'demo-education-support' },
  };

  beforeEach(() => jest.clearAllMocks());

  it('returns active beneficiaries with default newest-first ordering', async () => {
    prisma.beneficiary.findMany.mockResolvedValue([record]);

    await expect(service.findAll({})).resolves.toEqual([
      expect.objectContaining({
        id: 'beneficiary-1',
        name: 'Rahul Kumar',
        supportedYear: 2025,
        cause: { id: 'cause-1', slug: 'education' },
      }),
    ]);

    expect(prisma.beneficiary.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { isActive: true },
        orderBy: [
          { supportedYear: 'desc' },
          { displayOrder: 'asc' },
        ],
        include: { cause: true, organisation: true },
      }),
    );
  });

  it('applies cause, year and case-insensitive search filters', async () => {
    prisma.beneficiary.findMany.mockResolvedValue([]);

    await service.findAll({
      causeId: 'cause-1',
      year: 2025,
      search: 'rahul',
    });

    expect(prisma.beneficiary.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          isActive: true,
          causeId: 'cause-1',
          supportedYear: 2025,
          name: { contains: 'rahul', mode: 'insensitive' },
        },
      }),
    );
  });

  it('supports amount sorting', async () => {
    prisma.beneficiary.findMany.mockResolvedValue([]);

    await service.findAll({ sort: 'amount_desc' });

    expect(prisma.beneficiary.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ orderBy: { contributionAmount: 'desc' } }),
    );
  });

  it('returns one active beneficiary by id', async () => {
    prisma.beneficiary.findFirst.mockResolvedValue(record);

    await expect(service.findOne('beneficiary-1')).resolves.toEqual(
      expect.objectContaining({
        id: 'beneficiary-1',
        organisation: { id: 'org-1', slug: 'demo-education-support' },
      }),
    );

    expect(prisma.beneficiary.findFirst).toHaveBeenCalledWith({
      where: { id: 'beneficiary-1', isActive: true },
      include: { cause: true, organisation: true },
    });
  });

  it('throws NotFoundException when beneficiary does not exist', async () => {
    prisma.beneficiary.findFirst.mockResolvedValue(null);

    await expect(service.findOne('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
