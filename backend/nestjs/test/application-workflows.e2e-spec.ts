import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';

import {
  ApplicationRulesController,
  AdminApplicationRulesController,
  ApplicationWindowsController,
  AdminApplicationWindowsController,
  HelpApplicationsController,
  AdminHelpApplicationsController,
} from '../src/help-applications/help-applications.controller';
import { AdminGuard } from '../src/auth/admin.guard';
import { FirebaseAuthGuard } from '../src/auth/firebase-auth.guard';
import { ApplicationRulesService } from '../src/help-applications/application-rules.service';
import { ApplicationWindowsService } from '../src/help-applications/application-windows.service';
import { HelpApplicationsService } from '../src/help-applications/help-applications.service';

describe('Help & Recognition application HTTP workflows', () => {
  let app: INestApplication | undefined;
  const rulesService = { list: jest.fn(), listAdmin: jest.fn(), create: jest.fn(), update: jest.fn(), remove: jest.fn() };
  const windowsService = { list: jest.fn(), start: jest.fn(), close: jest.fn() };
  const applicationsService = {
    create: jest.fn(), listMine: jest.fn(), findMine: jest.fn(), deleteMine: jest.fn(), resubmit: jest.fn(),
    listForAdmin: jest.fn(), vote: jest.fn(), review: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      controllers: [
        ApplicationRulesController, AdminApplicationRulesController,
        ApplicationWindowsController, AdminApplicationWindowsController,
        HelpApplicationsController, AdminHelpApplicationsController,
      ],
      providers: [
        { provide: ApplicationRulesService, useValue: rulesService },
        { provide: ApplicationWindowsService, useValue: windowsService },
        { provide: HelpApplicationsService, useValue: applicationsService },
      ],
    })
      .overrideGuard(AdminGuard)
      .useValue({
        canActivate: (context: any) => {
          context.switchToHttp().getRequest().user = {
            uid: 'admin-firebase', email: 'admin@example.com', displayName: 'Admin',
          };
          return true;
        },
      })
      .overrideGuard(FirebaseAuthGuard)
      .useValue({
        canActivate: (context: any) => {
          context.switchToHttp().getRequest().user = {
            uid: 'user-firebase', email: 'user@example.com', displayName: 'User',
          };
          return true;
        },
      })
      .compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app?.close();
    app = undefined;
  });

  it('exposes scheduled/open/closed windows to the public client', async () => {
    windowsService.list.mockResolvedValue({
      serverNow: '2026-10-01T10:00:00.000Z',
      windows: [
        { type: 'EDUCATION_ASSISTANCE', status: 'SCHEDULED', canApply: false },
        { type: 'MEDICAL_HELP', status: 'OPEN', canApply: true },
        { type: 'PRATIBHA_SAMMAN', status: 'CLOSED', canApply: false },
      ],
    });
    await request(app!.getHttpServer())
      .get('/application-windows')
      .expect(200)
      .expect((response) => {
        expect(response.body.windows).toEqual(expect.arrayContaining([
          expect.objectContaining({ type: 'EDUCATION_ASSISTANCE', status: 'SCHEDULED', canApply: false }),
          expect.objectContaining({ type: 'MEDICAL_HELP', status: 'OPEN', canApply: true }),
          expect.objectContaining({ type: 'PRATIBHA_SAMMAN', status: 'CLOSED', canApply: false }),
        ]));
      });
  });

  it('starts, closes and reschedules a window through the admin HTTP boundary', async () => {
    windowsService.start.mockResolvedValue({ type: 'PRATIBHA_SAMMAN', status: 'OPEN', canApply: true });
    windowsService.close.mockResolvedValue({ type: 'PRATIBHA_SAMMAN', status: 'CLOSED', canApply: false });

    await request(app!.getHttpServer())
      .post('/admin/application-windows/PRATIBHA_SAMMAN/start')
      .send({ type: 'PRATIBHA_SAMMAN', startsAt: '2026-10-01T09:00:00.000Z' })
      .expect(201);

    await request(app!.getHttpServer())
      .post('/admin/application-windows/PRATIBHA_SAMMAN/close')
      .expect(201);

    expect(windowsService.start).toHaveBeenCalledWith(
      expect.objectContaining({ uid: 'admin-firebase' }), 'PRATIBHA_SAMMAN',
      expect.objectContaining({ type: 'PRATIBHA_SAMMAN' }),
    );
    expect(windowsService.close).toHaveBeenCalledWith(
      expect.objectContaining({ uid: 'admin-firebase' }), 'PRATIBHA_SAMMAN',
    );
  });

  it('serves localized rules and supports the admin rule lifecycle', async () => {
    rulesService.list.mockResolvedValue([
      { id: 'rule-1', type: 'PRATIBHA_SAMMAN', displayOrder: 1, text: 'केवल पुणे' },
    ]);
    rulesService.listAdmin.mockResolvedValue([{ id: 'rule-1', type: 'PRATIBHA_SAMMAN', displayOrder: 1 }]);
    rulesService.create.mockResolvedValue({ id: 'rule-1' });
    rulesService.update.mockResolvedValue({ id: 'rule-1' });
    rulesService.remove.mockResolvedValue({ id: 'rule-1', deleted: true });

    await request(app!.getHttpServer())
      .get('/application-rules/PRATIBHA_SAMMAN?language=hi')
      .expect(200)
      .expect([{ id: 'rule-1', type: 'PRATIBHA_SAMMAN', displayOrder: 1, text: 'केवल पुणे' }]);

    await request(app!.getHttpServer()).get('/admin/application-rules/PRATIBHA_SAMMAN').expect(200);
    await request(app!.getHttpServer()).post('/admin/application-rules').send({
      type: 'PRATIBHA_SAMMAN', displayOrder: 1,
      translations: [
        { language: 'en', text: 'Pune only' }, { language: 'hi', text: 'केवल पुणे' },
        { language: 'mr', text: 'फक्त पुणे' }, { language: 'gu', text: 'ફક્ત પુણે' },
      ],
    }).expect(201);
    await request(app!.getHttpServer()).patch('/admin/application-rules/rule-1').send({ displayOrder: 2 }).expect(200);
    await request(app!.getHttpServer()).delete('/admin/application-rules/rule-1').expect(200);

    expect(rulesService.list).toHaveBeenCalledWith('PRATIBHA_SAMMAN', 'hi');
    expect(rulesService.create).toHaveBeenCalled();
    expect(rulesService.update).toHaveBeenCalledWith('rule-1', expect.objectContaining({ displayOrder: 2 }));
    expect(rulesService.remove).toHaveBeenCalledWith('rule-1');
  });

  it('covers applicant create, history, detail and delete', async () => {
    applicationsService.create.mockResolvedValue({ id: 'app-1', type: 'MEDICAL_HELP', status: 'SUBMITTED' });
    applicationsService.listMine.mockResolvedValue([{ id: 'app-1', status: 'SUBMITTED' }]);
    applicationsService.findMine.mockResolvedValue({ id: 'app-1', status: 'SUBMITTED' });
    applicationsService.deleteMine.mockResolvedValue({ id: 'app-1', deleted: true });

    await request(app!.getHttpServer()).post('/applications').send({
      type: 'MEDICAL_HELP', applicantName: 'User', mobileNumber: '9876543210',
      address: '123 Test Street', city: 'Pune', state: 'Maharashtra', pincode: '411001',
      requestedAmount: 25000, mediaIds: ['media-1'], acceptedRuleIds: [],
    }).expect(201).expect(expect.objectContaining({ id: 'app-1', status: 'SUBMITTED' }));

    await request(app!.getHttpServer()).get('/applications/mine').expect(200);
    await request(app!.getHttpServer()).get('/applications/mine/app-1').expect(200);
    await request(app!.getHttpServer()).delete('/applications/mine/app-1').expect(200).expect({ id: 'app-1', deleted: true });

    expect(applicationsService.create).toHaveBeenCalledWith(
      expect.objectContaining({ uid: 'user-firebase' }), expect.objectContaining({ type: 'MEDICAL_HELP' }),
    );
    expect(applicationsService.deleteMine).toHaveBeenCalledWith(
      expect.objectContaining({ uid: 'user-firebase' }), 'app-1',
    );
  });

  it('covers resubmission and admin vote/review HTTP boundaries', async () => {
    applicationsService.resubmit.mockResolvedValue({ id: 'app-1', status: 'SUBMITTED' });
    applicationsService.vote.mockResolvedValue({ id: 'vote-1', score: 5 });
    applicationsService.review.mockResolvedValue({ id: 'app-1', status: 'CONSIDERED_FOR_SAMMAN' });

    await request(app!.getHttpServer()).patch('/applications/mine/app-1/resubmit')
      .send({ clarification: 'Updated evidence', mediaIds: ['media-2'], acceptedRuleIds: ['rule-1'] })
      .expect(200);

    await request(app!.getHttpServer()).post('/admin/applications/app-1/vote')
      .send({ score: 5 }).expect(201).expect({ id: 'vote-1', score: 5 });

    await request(app!.getHttpServer()).patch('/admin/applications/app-1/review')
      .send({ decision: 'CONSIDER_FOR_SAMMAN' }).expect(200)
      .expect({ id: 'app-1', status: 'CONSIDERED_FOR_SAMMAN' });

    expect(applicationsService.resubmit).toHaveBeenCalledWith(
      expect.objectContaining({ uid: 'user-firebase' }), 'app-1',
      expect.objectContaining({ clarification: 'Updated evidence' }),
    );
    expect(applicationsService.vote).toHaveBeenCalledWith(
      expect.objectContaining({ uid: 'admin-firebase' }), 'app-1', { score: 5 },
    );
    expect(applicationsService.review).toHaveBeenCalledWith('app-1', { decision: 'CONSIDER_FOR_SAMMAN' });
  });
});
