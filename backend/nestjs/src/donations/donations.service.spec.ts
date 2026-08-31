import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Decimal } from '@prisma/client/runtime/library';
import { DonationsService } from './donations.service';

describe('DonationsService', () => {
  let service: DonationsService;
  let prisma: {
    cause: { count: jest.Mock };
    donation: { create: jest.Mock; findUnique: jest.Mock };
  };

  beforeEach(() => {
    prisma = {
      cause: { count: jest.fn().mockResolvedValue(2) },
      donation: { create: jest.fn(), findUnique: jest.fn() },
    };
    service = new DonationsService(prisma as never);
  });

  const validInput = {
    amount: '1000.00',
    currency: 'INR',
    allocations: [
      { causeId: 'cause-1', amount: '600.00' },
      { causeId: 'cause-2', amount: '400.00' },
    ],
  };

  it('creates a donation allocated across causes without organisation selection', async () => {
    const created = { id: 'donation-1', amount: new Decimal('1000.00'), allocations: [] };
    prisma.donation.create.mockResolvedValue(created);

    await expect(service.create(validInput)).resolves.toEqual(created);
    expect(prisma.cause.count).toHaveBeenCalledWith({
      where: { id: { in: ['cause-1', 'cause-2'] }, isActive: true },
    });
    expect(prisma.donation.create).toHaveBeenCalledWith({
      data: {
        amount: new Decimal('1000.00'),
        currency: 'INR',
        allocations: {
          create: [
            { causeId: 'cause-1', amount: new Decimal('600.00') },
            { causeId: 'cause-2', amount: new Decimal('400.00') },
          ],
        },
      },
      include: { allocations: true },
    });
  });

  it.each([
    ['empty allocations', { ...validInput, allocations: [] }],
    ['allocation total mismatch', { ...validInput, allocations: [{ causeId: 'cause-1', amount: '999.00' }] }],
    ['duplicate cause', { ...validInput, allocations: [{ causeId: 'cause-1', amount: '500.00' }, { causeId: 'cause-1', amount: '500.00' }] }],
    ['zero donation', { ...validInput, amount: '0' }],
    ['negative donation', { ...validInput, amount: '-1' }],
    ['non-INR currency', { ...validInput, currency: 'USD' }],
  ])('rejects %s', async (_scenario, input) => {
    await expect(service.create(input)).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.donation.create).not.toHaveBeenCalled();
  });

  it('rejects inactive or missing causes', async () => {
    prisma.cause.count.mockResolvedValue(1);
    await expect(service.create(validInput))
      .rejects.toThrow('Donation allocations must reference active causes');
  });

  it('finds a donation with cause and organisation information when available', async () => {
    const donation = { id: 'donation-1', allocations: [] };
    prisma.donation.findUnique.mockResolvedValue(donation);
    await expect(service.findOne('donation-1')).resolves.toEqual(donation);
  });

  it('returns not found when the donation does not exist', async () => {
    prisma.donation.findUnique.mockResolvedValue(null);
    await expect(service.findOne('missing')).rejects.toBeInstanceOf(NotFoundException);
  });
});
