import { BadRequestException } from '@nestjs/common';
import { HelpApplicationsService } from './help-applications.service';
import { ApplicationWindowsService } from './application-windows.service';

describe('HelpApplicationsService', () => {
  const prisma: any = {
    user: { upsert: jest.fn() },
    media: { findMany: jest.fn(), findFirst: jest.fn() },
    applicationRule: { findMany: jest.fn() },
    helpApplicationRuleAcceptance: { deleteMany: jest.fn() },
    helpApplication: {
      create: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    helpApplicationMedia: { deleteMany: jest.fn() },
    helpApplicationVote: { upsert: jest.fn(), deleteMany: jest.fn() },
    cause: { findUnique: jest.fn() },
    beneficiary: { upsert: jest.fn() },
    beneficiaryMedia: { findFirst: jest.fn(), findMany: jest.fn(), create: jest.fn() },
    $transaction: jest.fn(),
  };
  const identity = { uid: 'firebase-1', email: 'user@example.com', displayName: 'User' };
  const applicationWindows = { ensureAccepting: jest.fn() } as unknown as ApplicationWindowsService;
  const mediaService = { deleteUserImage: jest.fn() } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.user.upsert.mockResolvedValue({ id: 'user-1', role: 'USER' });
    prisma.applicationRule.findMany.mockResolvedValue([]);
    prisma.media.findFirst.mockResolvedValue({ id: 'face-1' });
    (applicationWindows.ensureAccepting as jest.Mock).mockResolvedValue({ type: 'EDUCATION_ASSISTANCE' });
    prisma.$transaction.mockImplementation(async (callback: any) => callback(prisma));
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
      facePhotoMedia: { id: 'face-1', storageKey: 'applications/face.webp', mimeType: 'image/webp' },
    });

    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
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
      facePhotoMediaId: 'face-1',
    });

    expect(result.requestedAmount).toBe(25000);
    expect(prisma.helpApplication.create).toHaveBeenCalled();
  });

  it('blocks submission when the configured application window is closed', async () => {
    (applicationWindows.ensureAccepting as jest.Mock).mockRejectedValueOnce(new BadRequestException('Applications are no longer being accepted.'));
    prisma.media.findFirst.mockResolvedValue({ id: 'certificate-1' });
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);

    await expect(service.create(identity, {
      type: 'PRATIBHA_SAMMAN',
      applicantName: 'Test User',
      mobileNumber: '9876543210',
      address: '123 Test Street',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      mediaIds: ['media-1'],
      facePhotoMediaId: 'face-1',
    })).rejects.toThrow('Applications are no longer being accepted.');
    expect(prisma.media.findMany).not.toHaveBeenCalled();
    expect(prisma.helpApplication.create).not.toHaveBeenCalled();
  });

  it('requires evidence images and amount for assistance', async () => {
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
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
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
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
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
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
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
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
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
    await expect(service.review('app-1', { decision: 'CONSIDER_FOR_SAMMAN' }))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('deletes an applicant-owned application and rejects deletion after a final decision', async () => {
    prisma.helpApplication.findFirst.mockResolvedValueOnce({ id: 'app-1', status: 'SUBMITTED' });
    prisma.helpApplication.delete.mockResolvedValue({ id: 'app-1' });
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);

    await expect(service.deleteMine(identity, 'app-1')).resolves.toEqual({ id: 'app-1', deleted: true });
    expect(prisma.helpApplication.delete).toHaveBeenCalledWith({ where: { id: 'app-1' } });

    prisma.helpApplication.findFirst.mockResolvedValueOnce({ id: 'app-2', status: 'APPROVED_FOR_DONATION' });
    await expect(service.deleteMine(identity, 'app-2')).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.helpApplication.delete).toHaveBeenCalledTimes(1);
  });

  it('persists both Pratibha Samman review decisions', async () => {
    prisma.helpApplication.findUnique.mockResolvedValue({ id: 'app-1', type: 'PRATIBHA_SAMMAN', requestedAmount: null, media: [] });
    prisma.helpApplication.update.mockResolvedValue({ id: 'app-1', type: 'PRATIBHA_SAMMAN', status: 'CONSIDERED_FOR_SAMMAN', media: [], votes: [] });
    prisma.cause.findUnique.mockResolvedValue({ id: 'pratibha-cause' });
    prisma.beneficiary.upsert.mockResolvedValue({ id: 'beneficiary-1' });
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);

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
  it('publishes a selected Pratibha Samman application to the beneficiary explorer', async () => {
    prisma.helpApplication.findUnique.mockResolvedValue({
      id: 'app-1',
      type: 'PRATIBHA_SAMMAN',
      applicantName: 'Aarav Jain',
      classStandard: '10th',
      schoolInstituteName: 'Pune School',
      accomplishments: 'Passed 10th with distinction',
      adminNote: 'Selected for Pratibha Samman',
      certificatePhotoMediaId: 'certificate-1',
      media: [{ mediaId: 'evidence-1', media: { id: 'evidence-1' } }],
    });
    prisma.helpApplication.update.mockResolvedValue({
      id: 'app-1',
      type: 'PRATIBHA_SAMMAN',
      status: 'CONSIDERED_FOR_SAMMAN',
      applicantName: 'Aarav Jain',
      certificatePhotoMediaId: 'certificate-1',
      media: [{ mediaId: 'evidence-1', media: { id: 'evidence-1', storageKey: 'evidence.webp', mimeType: 'image/webp' } }],
      certificatePhotoMedia: { id: 'certificate-1', storageKey: 'certificate.webp', mimeType: 'image/webp' },
      votes: [],
    });
    prisma.cause.findUnique.mockResolvedValue({ id: 'pratibha-cause' });
    prisma.beneficiary.upsert.mockResolvedValue({ id: 'beneficiary-1' });
    prisma.beneficiaryMedia.findFirst.mockResolvedValue(null);
    prisma.beneficiaryMedia.findMany.mockResolvedValue([]);
    prisma.beneficiaryMedia.create.mockResolvedValue({});

    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
    await service.review('app-1', { decision: 'CONSIDER_FOR_SAMMAN' });

    expect(prisma.beneficiary.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { sourceApplicationId: 'app-1' },
      create: expect.objectContaining({
        sourceApplicationId: 'app-1',
        name: 'Aarav Jain',
        supportedYear: 2026,
        contributionAmount: 0,
        causeId: 'pratibha-cause',
      }),
    }));
    expect(prisma.beneficiaryMedia.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        beneficiaryId: 'beneficiary-1',
        mediaId: 'certificate-1',
        purpose: 'PROFILE',
        isPrimary: true,
      }),
    }));
    expect(prisma.beneficiaryMedia.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        beneficiaryId: 'beneficiary-1',
        mediaId: 'evidence-1',
        purpose: 'GALLERY',
      }),
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

    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
    const result = await service.vote(identity, 'app-1', { score: 5 });

    expect(result.score).toBe(5);
    expect(prisma.helpApplicationVote.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { applicationId_adminId: { applicationId: 'app-1', adminId: 'admin-1' } },
      }),
    );
  });

  it('rejects submission when not every active rule is acknowledged', async () => {
    prisma.media.findMany.mockResolvedValue([{ id: 'media-1' }]);
    prisma.media.findFirst.mockResolvedValue({ id: 'certificate-1' });
    prisma.applicationRule.findMany.mockResolvedValue([
      { id: 'rule-1', translations: [{ text: 'Pune only' }] },
      { id: 'rule-2', translations: [{ text: '80 percent minimum' }] },
    ]);
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);

    await expect(service.create(identity, {
      type: 'PRATIBHA_SAMMAN',
      applicantName: 'Test User',
      mobileNumber: '9876543210',
      address: '123 Test Street',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      mediaIds: ['media-1'],
      facePhotoMediaId: 'face-1',

      motherName: 'Mother User',
      fatherName: 'Father User',
      dateOfBirth: '2010-01-01T00:00:00.000Z',
      classStandard: '10',
      schoolInstituteName: 'Test School',
      certificatePhotoMediaId: 'certificate-1',
      acceptedRuleIds: ['rule-1'],
    })).rejects.toThrow('Please acknowledge every current application rule before submitting.');
    expect(prisma.helpApplication.create).not.toHaveBeenCalled();
  });

  it('stores the acknowledged rule text snapshot on successful submission', async () => {
    prisma.media.findMany.mockResolvedValue([{ id: 'media-1' }]);
    prisma.media.findFirst.mockResolvedValue({ id: 'certificate-1' });
    prisma.applicationRule.findMany.mockResolvedValue([
      { id: 'rule-1', translations: [{ text: 'Pune only' }] },
    ]);
    prisma.helpApplication.create.mockResolvedValue({
      id: 'app-1',
      type: 'PRATIBHA_SAMMAN',
      status: 'SUBMITTED',
      requestedAmount: null,
      approvedAmount: null,
      rejectionReason: null,
      clarification: null,
      adminNote: null,
      applicantName: 'Test User',
      mobileNumber: '9876543210',
      email: null,
      address: '123 Test Street',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      media: [],
    });
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);

    await service.create(identity, {
      type: 'PRATIBHA_SAMMAN',
      applicantName: 'Test User',
      mobileNumber: '9876543210',
      address: '123 Test Street',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      mediaIds: ['media-1'],
      facePhotoMediaId: 'face-1',

      motherName: 'Mother User',
      fatherName: 'Father User',
      dateOfBirth: '2010-01-01T00:00:00.000Z',
      classStandard: '10',
      schoolInstituteName: 'Test School',
      certificatePhotoMediaId: 'certificate-1',
      acceptedRuleIds: ['rule-1'],
    });

    expect(prisma.helpApplication.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        ruleAcceptances: { create: [{ ruleId: 'rule-1', ruleText: 'Pune only' }] },
      }),
    }));
  });

  it('updates a non-final application, replaces media and resets review state', async () => {
    prisma.helpApplication.findFirst.mockResolvedValue({
      id: 'app-1',
      applicantId: 'user-1',
      type: 'MEDICAL_HELP',
      status: 'UNDER_REVIEW',
      requestedAmount: 10000,
      media: [{ mediaId: 'old-media' }],
    });
    prisma.media.findMany.mockResolvedValue([{ id: 'new-media' }]);
    prisma.media.findFirst.mockResolvedValue({ id: 'new-face' });
    prisma.helpApplication.update.mockResolvedValue({
      id: 'app-1',
      type: 'MEDICAL_HELP',
      status: 'SUBMITTED',
      applicantName: 'Updated User',
      mobileNumber: '9876543210',
      email: null,
      address: 'Updated Address',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      requestedAmount: 15000,
      approvedAmount: null,
      rejectionReason: null,
      clarification: 'Updated need',
      media: [{ media: { id: 'new-media', storageKey: 'applications/new.webp', mimeType: 'image/webp' } }],
      facePhotoMedia: { id: 'new-face', storageKey: 'applications/face.webp', mimeType: 'image/webp' },
      certificatePhotoMedia: null,
    });
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);

    const result = await service.updateMine(identity, 'app-1', {
      applicantName: 'Updated User',
      mobileNumber: '9876543210',
      address: 'Updated Address',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      requestedAmount: 15000,
      clarification: 'Updated need',
      facePhotoMediaId: 'new-face',
      mediaIds: ['new-media'],
      acceptedRuleIds: [],
    });

    expect(result.status).toBe('SUBMITTED');
    expect(prisma.helpApplicationVote.deleteMany).toHaveBeenCalledWith({ where: { applicationId: 'app-1' } });
    expect(prisma.helpApplicationMedia.deleteMany).toHaveBeenCalledWith({ where: { applicationId: 'app-1' } });
    expect(mediaService.deleteUserImage).toHaveBeenCalledWith('old-media', 'user-1');
    expect(prisma.helpApplication.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ facePhotoMediaId: 'new-face', status: 'SUBMITTED' }),
    }));
  });

  it('rejects editing a final application', async () => {
    prisma.helpApplication.findFirst.mockResolvedValue({
      id: 'app-1',
      applicantId: 'user-1',
      type: 'MEDICAL_HELP',
      status: 'APPROVED_FOR_DONATION',
      media: [],
    });
    const service = new HelpApplicationsService(prisma, applicationWindows, mediaService);
    await expect(service.updateMine(identity, 'app-1', {
      applicantName: 'User',
      mobileNumber: '9876543210',
      address: 'Address',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      requestedAmount: 1000,
      facePhotoMediaId: 'face-1',
      mediaIds: ['media-1'],
      facePhotoMediaId: 'face-1',
      acceptedRuleIds: [],
    })).rejects.toThrow('can no longer be edited');
  });

});
