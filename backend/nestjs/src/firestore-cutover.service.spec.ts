import { BadRequestException } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirestoreAnalyticsService } from '../analytics/firestore-analytics.service';
import { FirestoreDonationsService } from '../donations/firestore-donations.service';
import { FirestoreApplicationRulesService } from '../help-applications/firestore-application-rules.service';
import { FirestoreApplicationWindowsService } from '../help-applications/firestore-application-windows.service';
import { FirestoreBeneficiariesService } from '../beneficiaries/firestore-beneficiaries.service';
import { FirestoreHelpApplicationsService } from '../help-applications/firestore-help-applications.service';
import { HelpApplicationTypeDto } from '../help-applications/dto/create-help-application.dto';
import { AdminDashboardService } from '../admin-dashboard/admin-dashboard.service';

function ref(id='doc-1') {
  return { id, set: jest.fn(), update: jest.fn(), delete: jest.fn(), get: jest.fn() };
}

function collection() {
  const document = ref();
  return {
    doc: jest.fn(() => document),
    where: jest.fn(() => collection()),
    orderBy: jest.fn(() => collection()),
    limit: jest.fn(() => collection()),
    get: jest.fn(async () => ({ docs: [], empty: true })),
    count: jest.fn(() => ({ get: jest.fn(async () => ({ data: () => ({ count: 0 }) })) })),
  };
}

describe('Firestore cutover services', () => {
  it('writes analytics events in one bounded batch', async () => {
    const batch = { set: jest.fn(), commit: jest.fn().mockResolvedValue(undefined) };
    const db = { batch: jest.fn(() => batch), collection: jest.fn(() => ({ doc: jest.fn(() => ref('event-1')) })) };
    const service = new FirestoreAnalyticsService({ db } as any);

    await service.trackBatch([{
      clientId: 'abcdef0123456789',
      sessionId: '0123456789abcdef',
      eventName: 'screen_view',
      screenName: 'home',
    }]);

    expect(batch.set).toHaveBeenCalledTimes(1);
    expect(batch.commit).toHaveBeenCalledTimes(1);
  });

  it('rejects analytics batches above the Firestore limit', async () => {
    const service = new FirestoreAnalyticsService({ db: { batch: jest.fn(), collection: jest.fn() } } as any);
    const events = Array.from({ length: 51 }, () => ({
      clientId: 'abcdef0123456789',
      sessionId: '0123456789abcdef',
      eventName: 'screen_view' as const,
    }));
    await expect(service.trackBatch(events)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('validates and stores all four application-rule translations', async () => {
    const document = ref('rule-1');
    const db = { collection: jest.fn(() => ({ doc: jest.fn(() => document) })) };
    const service = new FirestoreApplicationRulesService({ db } as any);
    const result = await service.create({
      type: HelpApplicationTypeDto.EDUCATION_ASSISTANCE,
      displayOrder: 1,
      translations: [
        { language: 'en', text: 'English' },
        { language: 'hi', text: 'Hindi' },
        { language: 'mr', text: 'Marathi' },
        { language: 'gu', text: 'Gujarati' },
      ],
    } as any);
    expect(result.translations).toEqual({ en: 'English', hi: 'Hindi', mr: 'Marathi', gu: 'Gujarati' });
    expect(document.set).toHaveBeenCalled();
  });

  it('rejects an application rule with missing translations', async () => {
    const service = new FirestoreApplicationRulesService({ db: { collection: jest.fn() } } as any);
    await expect(service.create({
      type: HelpApplicationTypeDto.EDUCATION_ASSISTANCE,
      displayOrder: 1,
      translations: [{ language: 'en', text: 'Only English' }],
    } as any)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('reports an open application window when the persisted window is active', async () => {
    const now = new Date();
    const window = {
      type: HelpApplicationTypeDto.MEDICAL_HELP,
      startsAt: Timestamp.fromDate(new Date(now.getTime() - 60_000)),
      registrationEndsAt: Timestamp.fromDate(new Date(now.getTime() + 3_600_000)),
      eventAt: null,
      closedAt: null,
      updatedById: 'admin-1',
      updatedAt: Timestamp.now(),
    };
    const doc = ref(HelpApplicationTypeDto.MEDICAL_HELP);
    doc.get.mockResolvedValue({ exists: true, data: () => window });
    const db = { collection: jest.fn(() => ({ doc: jest.fn(() => doc) })) };
    const service = new FirestoreApplicationWindowsService({ db } as any, {} as any);

    await expect(service.ensureAccepting(HelpApplicationTypeDto.MEDICAL_HELP)).resolves.toMatchObject({ status: 'OPEN', canApply: true });
  });

  it('creates a beneficiary in Firestore without a PostgreSQL dependency', async () => {
    const document = ref();
    const db = { collection: jest.fn(() => ({ doc: jest.fn(() => document) })) };
    const service = new FirestoreBeneficiariesService({ db } as any);
    const result = await service.create({ name: 'Test Beneficiary', causeId: 'cause-1' });
    expect(result.name).toBe('Test Beneficiary');
    expect(document.set).toHaveBeenCalledWith(expect.objectContaining({ causeId: 'cause-1', isActive: true }));
  });

  it('creates a donation atomically against active causes', async () => {
    const transaction = {
      getAll: jest.fn().mockResolvedValue([{ exists: true, data: () => ({ isActive: true }) }]),
      set: jest.fn(),
    };
    const causeRef = ref('cause-1');
    const db = {
      collection: jest.fn(() => ({ doc: jest.fn(() => causeRef) })),
      runTransaction: jest.fn(async (callback: any) => callback(transaction)),
    };
    const service = new FirestoreDonationsService({ db } as any);

    const result = await service.create({ amount: '100.00', currency: 'INR', allocations: [{ causeId: 'cause-1', amount: '100.00' }] });
    expect(result.amount).toBe('100.00');
    expect(transaction.set).toHaveBeenCalledTimes(1);
  });

  it('returns a Firestore help application owned by the authenticated user', async () => {
    const document = ref('application-1');
    const item = {
      id: 'application-1',
      applicantId: 'user-1',
      applicantName: 'Applicant',
      mobileNumber: '9999999999',
      email: null,
      address: 'Address',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      type: HelpApplicationTypeDto.MEDICAL_HELP,
      status: 'SUBMITTED',
      requestedAmount: 100,
      overallPercentage: 80,
      approvedAmount: null,
      rejectionReason: null,
      clarification: null,
      motherName: null,
      fatherName: null,
      dateOfBirth: null,
      classStandard: null,
      schoolInstituteName: null,
      accomplishments: null,
      certificatePhotoMediaId: null,
      facePhotoMediaId: 'face-1',
      adminNote: null,
      submittedAt: Timestamp.now(),
      reviewedAt: null,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      media: [],
      ruleAcceptances: [],
    };
    document.get.mockResolvedValue({ exists: true, data: () => item });
    const db = { collection: jest.fn(() => ({ doc: jest.fn(() => document) })) };
    const service = new FirestoreHelpApplicationsService(
      { db } as any,
      { upsertFromIdentity: jest.fn().mockResolvedValue({ id: 'user-1' }) } as any,
      { getById: jest.fn() } as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );
    const result = await service.findMine({ uid: 'firebase-user' } as any, 'application-1');
    expect(result.id).toBe('application-1');
    expect(result.applicantName).toBe('Applicant');
  });

  it('uses Firestore counts for the admin dashboard summary', async () => {
    const counts: Record<string, number> = { causes: 3, organisations: 2, beneficiaries: 5 };
    const db = {
      collection: jest.fn((name: string) => ({
        count: jest.fn(() => ({ get: jest.fn(async () => ({ data: () => ({ count: counts[name] ?? 0 }) })) })),
        where: jest.fn(() => ({ count: jest.fn(() => ({ get: jest.fn(async () => ({ data: () => ({ count: Math.max(0, (counts[name] ?? 0) - 1) }) })) })) })),
      })),
    };
    const analytics = {} as any;
    const service = new AdminDashboardService({ db } as any, analytics);
    await expect(service.getSummary()).resolves.toEqual({
      causes: { total: 3, active: 2, inactive: 1 },
      organisations: { total: 2, active: 1, inactive: 1 },
      beneficiaries: { total: 5, active: 4, inactive: 1 },
    });
  });
});
