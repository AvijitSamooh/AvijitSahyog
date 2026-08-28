import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { DonationsService } from './donations.service';

describe('DonationsService', () => {
  let service: DonationsService;
  let prisma: {
    organisationCause: { findMany: jest.Mock };
    donation: { findUnique: jest.Mock };
    $transaction: jest.Mock;
  };

  beforeEach(() => {
    prisma = {
      organisationCause: { findMany: jest.fn() },
      donation: { findUnique: jest.fn() },
      $transaction: jest.fn(),
    };

    service = new DonationsService(prisma as never);
  });

  const relationship = {
    causeId: 'cause-1',
    organisationId: 'org-1',
  };

  const validInput = {
    amount: '1000.00',
    currency: 'INR',
    allocations: [
      { causeId: 'cause-1', organisationId: 'org-1', amount: '600.00' },
      { causeId: 'cause-2', organisationId: 'org-2', amount: '400.00' },
    ],
  };

  it('creates a valid donation when allocations equal the donation amount', async () => {
    prisma.organisationCause.findMany.mockResolvedValue([
      relationship,
      { causeId: 'cause-2', organisationId: 'org-2' },
    ]);

    const createdDonation = {
      id: 'donation-1',
      amount: new Prisma.Decimal('1000.00'),
      currency: 'INR',
      allocations: [],
    };

    const tx = {
      donation: {
        create: jest.fn().mockResolvedValue(createdDonation),
      },
    };
    prisma.$transaction.mockImplementation(async (callback) => callback(tx));

    await expect(service.create(validInput)).resolves.toEqual(createdDonation);
    expect(tx.donation.create).toHaveBeenCalledWith({
      data: {
        amount: new Prisma.Decimal('1000.00'),
        currency: 'INR',
        allocations: {
          create: [
            {
              causeId: 'cause-1',
              organisationId: 'org-1',
              amount: new Prisma.Decimal('600.00'),
            },
            {
              causeId: 'cause-2',
              organisationId: 'org-2',
              amount: new Prisma.Decimal('400.00'),
            },
          ],
        },
      },
      include: { allocations: true },
    });
  });

  it('defaults the currency to INR', async () => {
    prisma.organisationCause.findMany.mockResolvedValue([relationship]);
    const tx = {
      donation: { create: jest.fn().mockResolvedValue({ id: 'donation-1' }) },
    };
    prisma.$transaction.mockImplementation(async (callback) => callback(tx));

    await service.create({
      amount: '100.00',
      allocations: [
        { causeId: 'cause-1', organisationId: 'org-1', amount: '100.00' },
      ],
    });

    expect(tx.donation.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ currency: 'INR' }),
      }),
    );
  });

  it.each([
    ['zero donation', { ...validInput, amount: '0' }],
    ['negative donation', { ...validInput, amount: '-1' }],
    ['non-INR currency', { ...validInput, currency: 'USD' }],
    ['no allocations', { ...validInput, allocations: [] }],
    [
      'zero allocation',
      {
        ...validInput,
        allocations: [
          { causeId: 'cause-1', organisationId: 'org-1', amount: '0' },
        ],
      },
    ],
    [
      'negative allocation',
      {
        ...validInput,
        allocations: [
          { causeId: 'cause-1', organisationId: 'org-1', amount: '-10' },
        ],
      },
    ],
  ])('rejects %s', async (_scenario, input) => {
    await expect(service.create(input)).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.organisationCause.findMany).not.toHaveBeenCalled();
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects an allocation total that does not equal the donation amount', async () => {
    const input = {
      ...validInput,
      allocations: [
        { causeId: 'cause-1', organisationId: 'org-1', amount: '600.00' },
        { causeId: 'cause-2', organisationId: 'org-2', amount: '300.00' },
      ],
    };

    await expect(service.create(input)).rejects.toThrow(
      'Donation amount must equal the sum of its allocations',
    );
    expect(prisma.organisationCause.findMany).not.toHaveBeenCalled();
  });

  it('rejects an invalid decimal amount', async () => {
    await expect(
      service.create({
        ...validInput,
        amount: 'not-a-number',
      }),
    ).rejects.toThrow('Donation amount must be a valid decimal amount');
  });

  it('rejects an allocation without an active cause-organisation relationship', async () => {
    prisma.organisationCause.findMany.mockResolvedValue([relationship]);

    await expect(
      service.create({
        amount: '1000.00',
        allocations: [
          { causeId: 'cause-1', organisationId: 'org-1', amount: '500.00' },
          { causeId: 'cause-2', organisationId: 'org-2', amount: '500.00' },
        ],
      }),
    ).rejects.toThrow(
      'Each allocation must reference an active cause-organisation relationship',
    );

    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('finds a donation with its cause and organisation allocations', async () => {
    const donation = {
      id: 'donation-1',
      allocations: [
        {
          cause: { id: 'cause-1' },
          organisation: { id: 'org-1' },
        },
      ],
    };
    prisma.donation.findUnique.mockResolvedValue(donation);

    await expect(service.findOne('donation-1')).resolves.toEqual(donation);
    expect(prisma.donation.findUnique).toHaveBeenCalledWith({
      where: { id: 'donation-1' },
      include: {
        allocations: {
          include: {
            cause: true,
            organisation: true,
          },
        },
      },
    });
  });

  it('returns not found when the donation does not exist', async () => {
    prisma.donation.findUnique.mockResolvedValue(null);

    await expect(service.findOne('missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
