import { BadRequestException } from '@nestjs/common';
import { HelpApplicationsService } from './help-applications.service';

describe('HelpApplicationsService', () => {
  const prisma: any = {
    user: { upsert: jest.fn() },
    media: { findMany: jest.fn() },
    helpApplication: {
      create: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    helpApplicationMedia: { deleteMany: jest.fn() },
    helpApplicationVote: { upsert: jest.fn() },
    $transaction: jest.fn(),
  };
  const identity = { uid: 'firebase-1', email: 'user@example.com', displayName: 'User' };

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.user.upsert.mockResolvedValue({ id: 'user-1', role: 'USER' });
  });

  it('creates an assistance application with requested amount and evidence', async () => {
    prisma.media.findMany.mockResolvedValue([{ id: 'media-1' }]);
    prisma.helpApplication.create.mockResolvedValue({
      id: 'app-1',
      type: 'EDUCATION_ASSISTANCE',
      status: 'SUBMITTED',
      requestedAmount: 25000,
      approvedAmount: null,
      rejectionReason: null,
      clarification: null,
      adminNote: null,
      applicantName: 'Test User', mobileNumber: '9876543210', email: null, address: '123 Test Street', city: 'Pune', state: 'Maharashtra', pincode: '411001',
      media: [{ media: { id: 'media-1', storageKey: 'applications/a.webp', mimeType: 'image/webp' } }],
    });

    const service = new HelpApplicationsService(prisma);
    const result = await service.create(identity, {
      type: 'EDUCATION_ASSISTANCE',
      applicantName: 'Test User',
      mobileNumber: '9876543210',
      address: '123 Test Street',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      requestedAmount: 25000,
      mediaIds: ['media-1'],
    });

    expect(result.requestedAmount).toBe(25000);
    expect(prisma.helpApplication.create).toHaveBeenCalled();
  });

  it('requires evidence images and amount for assistance', async () => {
    const service = new HelpApplicationsService(prisma);
    await expect(service.create(identity, {
      type: 'MEDICAL_HELP',
      applicantName: 'Test User',
      mobileNumber: '9876543210',
      address: '123 Test Street',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      requestedAmount: undefined,
      mediaIds: [],
    })).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.helpApplication.create).not.toHaveBeenCalled();
  });

  it('requires evidence for Pratibha Samman', async () => {
    const service = new HelpApplicationsService(prisma);
    await expect(service.create(identity, {
      type: 'PRATIBHA_SAMMAN',
      applicantName: 'Test User',
      mobileNumber: '9876543210',
      address: '123 Test Street',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      mediaIds: [],
    })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects an assistance approval above the requested amount', async () => {
    prisma.helpApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      type: 'MEDICAL_HELP',
      requestedAmount: 10000,
      media: [],
    });
    const service = new HelpApplicationsService(prisma);
    await expect(service.review('app-1', {
      decision: 'APPROVE',
      approvedAmount: 12000,
    })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('requires a reason when rejecting an application', async () => {
    prisma.helpApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      type: 'EDUCATION_ASSISTANCE',
      requestedAmount: 10000,
      media: [],
    });
    const service = new HelpApplicationsService(prisma);
    await expect(service.review('app-1', { decision: 'REJECT' }))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('only permits Samman decisions for Pratibha applications', async () => {
    prisma.helpApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      type: 'MEDICAL_HELP',
      requestedAmount: 10000,
      media: [],
    });
    const service = new HelpApplicationsService(prisma);
    await expect(service.review('app-1', { decision: 'CONSIDER_FOR_SAMMAN' }))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('deletes an applicant-owned application and rejects deletion after a final decision', async () => {
    prisma.helpApplication.findFirst.mockResolvedValueOnce({ id: 'app-1', status: 'SUBMITTED' });
    prisma.helpApplication.delete.mockResolvedValue({ id: 'app-1' });
    const service = new HelpApplicationsService(prisma);

    await expect(service.deleteMine(identity, 'app-1')).resolves.toEqual({ id: 'app-1', deleted: true });
    expect(prisma.helpApplication.delete).toHaveBeenCalledWith({ where: { id: 'app-1' } });

    prisma.helpApplication.findFirst.mockResolvedValueOnce({ id: 'app-2', status: 'APPROVED_FOR_DONATION' });
    await expect(service.deleteMine(identity, 'app-2')).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.helpApplication.delete).toHaveBeenCalledTimes(1);
  });

  it('persists both Pratibha Samman review decisions', async () => {
    prisma.helpApplication.findUnique.mockResolvedValue({ id: 'app-1', type: 'PRATIBHA_SAMMAN', requestedAmount: null, media: [] });
    prisma.helpApplication.update.mockResolvedValue({ id: 'app-1', type: 'PRATIBHA_SAMMAN', status: 'CONSIDERED_FOR_SAMMAN', media: [], votes: [] });
    const service = new HelpApplicationsService(prisma);

    await service.review('app-1', { decision: 'CONSIDER_FOR_SAMMAN' });
    expect(prisma.helpApplication.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'app-1' },
      data: expect.objectContaining({ status: 'CONSIDERED_FOR_SAMMAN' }),
    }));

    prisma.helpApplication.update.mockResolvedValue({ id: 'app-1', type: 'PRATIBHA_SAMMAN', status: 'NOT_SELECTED', media: [], votes: [] });
    await service.review('app-1', { decision: 'NOT_SELECTED' });
    expect(prisma.helpApplication.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'app-1' },
      data: expect.objectContaining({ status: 'NOT_SELECTED' }),
    }));
  });
  it('upserts one vote per administrator and supports score 1 to 5', async () => {
    prisma.user.upsert.mockResolvedValue({ id: 'admin-1', role: 'ADMIN' });
    prisma.helpApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      type: 'PRATIBHA_SAMMAN',
      media: [],
    });
    prisma.$transaction.mockImplementation(async (callback: any) => callback(prisma));
    prisma.helpApplicationVote.upsert.mockResolvedValue({
      id: 'vote-1',
      applicationId: 'app-1',
      adminId: 'admin-1',
      score: 5,
    });

    const service = new HelpApplicationsService(prisma);
    const result = await service.vote(identity, 'app-1', { score: 5 });

    expect(result.score).toBe(5);
    expect(prisma.helpApplicationVote.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { applicationId_adminId: { applicationId: 'app-1', adminId: 'admin-1' } },
      }),
    );
  });
});
