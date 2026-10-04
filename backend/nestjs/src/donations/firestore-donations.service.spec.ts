import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirestoreDonationsService } from './firestore-donations.service';

describe('FirestoreDonationsService', () => {
  function makeService(options: any = {}) {
    const causeData = options.causeData ?? { id: 'cause-1', slug: 'medical', isActive: true };
    const causeRef = { id: 'cause-1' };
    const donationRef = { id: 'donation-1' };
    const transaction = {
      getAll: jest.fn().mockResolvedValue([{ id: 'cause-1', exists: true, data: () => causeData }]),
      set: jest.fn(),
    };
    const causes = {
      doc: jest.fn().mockReturnValue(causeRef),
    };
    const donations = {
      doc: jest.fn().mockReturnValue(donationRef),
    };
    const db = {
      collection: jest.fn((name: string) => name === 'causes' ? causes : donations),
      runTransaction: jest.fn(async (callback: any) => callback(transaction)),
    };
    return { service: new FirestoreDonationsService({ db } as any), db, transaction, donations, causes };
  }

  it('creates a valid INR donation and allocation', async () => {
    const { service, transaction } = makeService();
    const result = await service.create({
      amount: '100.50',
      currency: 'INR',
      allocations: [{ causeId: 'cause-1', amount: '100.50' }],
    } as any);

    expect(result.amount).toBe('100.50');
    expect(result.status).toBe('PENDING');
    expect(result.allocations[0].amount).toBe('100.50');
    expect(transaction.set).toHaveBeenCalled();
  });

  it('defaults currency to INR', async () => {
    const { service } = makeService();
    await expect(service.create({
      amount: '10',
      allocations: [{ causeId: 'cause-1', amount: '10' }],
    } as any)).resolves.toEqual(expect.objectContaining({ currency: 'INR' }));
  });

  it.each([
    ['bad decimal', '10.123'],
    ['negative', '-1'],
    ['empty', ''],
  ])('rejects %s donation amount', async (_label, amount) => {
    const { service } = makeService();
    await expect(service.create({
      amount,
      currency: 'INR',
      allocations: [{ causeId: 'cause-1', amount: amount || '1' }],
    } as any)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects unsupported currency and missing allocations', async () => {
    const { service } = makeService();
    await expect(service.create({
      amount: '10', currency: 'USD', allocations: [{ causeId: 'cause-1', amount: '10' }],
    } as any)).rejects.toThrow('Only INR');
    await expect(service.create({ amount: '10', allocations: [] } as any))
      .rejects.toThrow('at least one cause');
  });

  it('rejects invalid, duplicate and mismatched allocations', async () => {
    const { service } = makeService();
    await expect(service.create({
      amount: '10', allocations: [{ causeId: 'cause-1', amount: '0' }],
    } as any)).rejects.toThrow('greater than zero');
    await expect(service.create({
      amount: '10', allocations: [
        { causeId: 'cause-1', amount: '5' },
        { causeId: 'cause-1', amount: '5' },
      ],
    } as any)).rejects.toThrow('only appear once');
    await expect(service.create({
      amount: '10', allocations: [{ causeId: 'cause-1', amount: '9' }],
    } as any)).rejects.toThrow('Allocation total');
  });

  it('rejects allocations to inactive causes', async () => {
    const { service } = makeService({ causeData: { id: 'cause-1', isActive: false } });
    await expect(service.create({
      amount: '10', allocations: [{ causeId: 'cause-1', amount: '10' }],
    } as any)).rejects.toThrow('active causes');
  });

  it('rejects a missing cause snapshot', async () => {
    const { service } = makeService();
    const db: any = (service as any).firebase.db;
    const tx = {
      getAll: jest.fn().mockResolvedValue([]),
      set: jest.fn(),
    };
    db.runTransaction.mockImplementation(async (callback: any) => callback(tx));
    await expect(service.create({
      amount: '10', allocations: [{ causeId: 'cause-1', amount: '10' }],
    } as any)).rejects.toThrow('active causes');
  });

  it('finds a donation and resolves cause metadata', async () => {
    const created = Timestamp.now();
    const cause = { id: 'cause-1', slug: 'medical' };
    const doc = {
      id: 'donation-1',
      exists: true,
      data: () => ({
        id: 'donation-1',
        amount: '10.00',
        status: 'PENDING',
        createdAt: created,
        updatedAt: new Date(),
        allocations: [{ causeId: 'cause-1', amount: '10.00', createdAt: created }],
      }),
    };
    const causeDoc = { id: 'cause-1', exists: true, data: () => cause };
    const db: any = {
      collection: jest.fn((name: string) => ({
        doc: jest.fn((id: string) => ({
          get: jest.fn().mockResolvedValue(name === 'donations' ? doc : causeDoc),
        })),
      })),
    };
    const service = new FirestoreDonationsService({ db } as any);
    const result = await service.findOne('donation-1');
    expect(result.allocations[0].cause).toEqual({ id: 'cause-1', slug: 'medical' });
    expect(result.createdAt).toBeInstanceOf(Date);
  });

  it('rejects an unknown donation', async () => {
    const db: any = { collection: jest.fn(() => ({
      doc: jest.fn(() => ({ get: jest.fn().mockResolvedValue({ exists: false }) })),
    })) };
    const service = new FirestoreDonationsService({ db } as any);
    await expect(service.findOne('missing')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('finds donations with missing allocation causes as null', async () => {
    const created = Timestamp.now();
    const db: any = {
      collection: jest.fn((name: string) => ({
        doc: jest.fn(() => ({
          get: jest.fn().mockResolvedValue(name === 'donations'
            ? { exists: true, data: () => ({ allocations: [{ causeId: 'missing', amount: 1, createdAt: created }] }) }
            : { exists: false }),
        })),
      })),
    };
    const service = new FirestoreDonationsService({ db } as any);
    const result = await service.findOne('donation');
    expect(result.allocations[0].cause).toBeNull();
  });
});
