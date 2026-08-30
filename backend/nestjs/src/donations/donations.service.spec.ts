import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Decimal } from '@prisma/client/runtime/library';
import { DonationsService } from './donations.service';

describe('DonationsService', () => {
  let service: DonationsService;
  let prisma: {
    cause: { findFirst: jest.Mock };
    donation: { create: jest.Mock; findUnique: jest.Mock };
  };

  beforeEach(() => {
    prisma = {
      cause: { findFirst: jest.fn().mockResolvedValue({ id: 'cause-1' }) },
      donation: { create: jest.fn(), findUnique: jest.fn() },
    };
    service = new DonationsService(prisma as never);
  });

  const validInput = { amount: '1000.00', currency: 'INR', causeId: 'cause-1' };

  it('creates a cause-level donation without organisation selection', async () => {
    const created = { id: 'donation-1', amount: new Decimal('1000.00'), currency: 'INR', allocations: [] };
    prisma.donation.create.mockResolvedValue(created);

    await expect(service.create(validInput)).resolves.toEqual(created);
    expect(prisma.cause.findFirst).toHaveBeenCalledWith({
      where: { id: 'cause-1', isActive: true },
      select: { id: true },
    });
    expect(prisma.donation.create).toHaveBeenCalledWith({
      data: {
        amount: new Decimal('1000.00'),
        currency: 'INR',
        allocations: { create: [{ causeId: 'cause-1', amount: new Decimal('1000.00') }] },
      },
      include: { allocations: true },
    });
  });

  it('defaults currency to INR', async () => {
    prisma.donation.create.mockResolvedValue({ id: 'donation-1' });
    await service.create({ amount: '100.00', causeId: 'cause-1' });
    expect(prisma.donation.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ currency: 'INR' }),
    }));
  });

  it.each([
    ['zero donation', { ...validInput, amount: '0' }],
    ['negative donation', { ...validInput, amount: '-1' }],
    ['non-INR currency', { ...validInput, currency: 'USD' }],
  ])('rejects %s', async (_scenario, input) => {
    await expect(service.create(input)).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.cause.findFirst).not.toHaveBeenCalled();
  });

  it('rejects an invalid decimal amount', async () => {
    await expect(service.create({ ...validInput, amount: 'not-a-number' }))
      .rejects.toThrow('Donation amount must be a valid decimal amount');
  });

  it('rejects an inactive or missing cause', async () => {
    prisma.cause.findFirst.mockResolvedValue(null);
    await expect(service.create(validInput))
      .rejects.toThrow('Donation must reference an active cause');
    expect(prisma.donation.create).not.toHaveBeenCalled();
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
