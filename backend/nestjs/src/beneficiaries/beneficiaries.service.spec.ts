import { BadRequestException, NotFoundException } from '@nestjs/common';
import { BeneficiariesService } from './beneficiaries.service';

describe('BeneficiariesService', () => {
  const prisma = {
    beneficiary: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    cause: { findUnique: jest.fn() },
    organisation: { findUnique: jest.fn() },
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
        include: expect.objectContaining({ cause: true, organisation: true, media: expect.any(Object) }),
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
      include: expect.objectContaining({ cause: true, organisation: true, media: expect.any(Object) }),
    });
  });

  it('throws NotFoundException when beneficiary does not exist', async () => {
    prisma.beneficiary.findFirst.mockResolvedValue(null);

    await expect(service.findOne('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('creates a beneficiary after validating cause and organisation', async () => {
    prisma.cause.findUnique.mockResolvedValue({ id: 'cause-1' });
    prisma.organisation.findUnique.mockResolvedValue({ id: 'org-1' });
    prisma.beneficiary.create.mockResolvedValue(record);

    await expect(
      service.create({
        name: 'Rahul Kumar',
        supportedYear: 2025,
        contributionAmount: 25000,
        causeId: 'cause-1',
        organisationId: 'org-1',
      }),
    ).resolves.toEqual(record);
  });

  it('rejects a beneficiary without a valid contribution amount', async () => {
    await expect(
      service.create({
        name: 'Rahul',
        supportedYear: 2025,
        contributionAmount: 0,
        causeId: 'cause-1',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects an unknown cause during creation', async () => {
    prisma.cause.findUnique.mockResolvedValue(null);

    await expect(
      service.create({
        name: 'Rahul',
        supportedYear: 2025,
        contributionAmount: 100,
        causeId: 'missing',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects an unknown organisation during creation', async () => {
    prisma.cause.findUnique.mockResolvedValue({ id: 'cause-1' });
    prisma.organisation.findUnique.mockResolvedValue(null);

    await expect(
      service.create({
        name: 'Rahul',
        supportedYear: 2025,
        contributionAmount: 100,
        causeId: 'cause-1',
        organisationId: 'missing-org',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.beneficiary.create).not.toHaveBeenCalled();
  });

  it('deactivates an existing beneficiary', async () => {
    prisma.beneficiary.findUnique.mockResolvedValue(record);
    prisma.beneficiary.update.mockResolvedValue({ ...record, isActive: false });

    await expect(service.setActive('beneficiary-1', false)).resolves.toEqual(
      expect.objectContaining({ isActive: false }),
    );
  });
});
