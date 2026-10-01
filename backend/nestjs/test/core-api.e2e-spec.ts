import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';

import { CausesController } from '../src/causes/causes.controller';
import { CausesService } from '../src/causes/causes.service';
import { OrganisationsController } from '../src/organisations/organisations.controller';
import { OrganisationsService } from '../src/organisations/organisations.service';
import { BeneficiariesController } from '../src/beneficiaries/beneficiaries.controller';
import { BeneficiariesService } from '../src/beneficiaries/beneficiaries.service';
import { AuthController } from '../src/auth/auth.controller';
import { AuthService } from '../src/auth/auth.service';
import { FirebaseAuthGuard } from '../src/auth/firebase-auth.guard';
import { AdminDashboardController } from '../src/admin-dashboard/admin-dashboard.controller';
import { AdminDashboardService } from '../src/admin-dashboard/admin-dashboard.service';
import { AdminGuard } from '../src/auth/admin.guard';
import { SuperAdminGuard } from '../src/auth/super-admin.guard';
import { PlatformHealthController } from '../src/platform-health/platform-health.controller';
import { PlatformHealthService } from '../src/platform-health/platform-health.service';

describe('Core public/auth/admin HTTP contracts', () => {
  let app: INestApplication | undefined;
  const causes = { findAll: jest.fn(), findOne: jest.fn() };
  const organisations = { findAll: jest.fn(), findOne: jest.fn() };
  const beneficiaries = { findAll: jest.fn(), findOne: jest.fn() };
  const auth = { getCurrentUser: jest.fn() };
  const dashboard = { getSummary: jest.fn(), getAnalytics: jest.fn(), getAdvancedAnalytics: jest.fn() };
  const health = { checkDatabase: jest.fn(), getSummary: jest.fn(), recordEvent: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      controllers: [
        CausesController, OrganisationsController, BeneficiariesController,
        AuthController, AdminDashboardController, PlatformHealthController,
      ],
      providers: [
        { provide: CausesService, useValue: causes },
        { provide: OrganisationsService, useValue: organisations },
        { provide: BeneficiariesService, useValue: beneficiaries },
        { provide: AuthService, useValue: auth },
        { provide: AdminDashboardService, useValue: dashboard },
        { provide: PlatformHealthService, useValue: health },
      ],
    })
      .overrideGuard(FirebaseAuthGuard)
      .useValue({
        canActivate: (context: any) => {
          context.switchToHttp().getRequest().user = { uid: 'firebase-1', email: 'user@example.com' };
          return true;
        },
      })
      .overrideGuard(AdminGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(SuperAdminGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app?.close();
    app = undefined;
  });

  it('routes localized public discovery queries', async () => {
    causes.findAll.mockResolvedValue([{ slug: 'education', name: 'शिक्षा' }]);
    causes.findOne.mockResolvedValue({ slug: 'education', name: 'शिक्षा' });
    organisations.findAll.mockResolvedValue([{ slug: 'seva', name: 'सेवा' }]);
    organisations.findOne.mockResolvedValue({ slug: 'seva', name: 'सेवा' });
    beneficiaries.findAll.mockResolvedValue([{ id: 'b-1', name: 'Student' }]);
    beneficiaries.findOne.mockResolvedValue({ id: 'b-1', name: 'Student' });

    await request(app!.getHttpServer()).get('/causes?language=hi').expect(200);
    await request(app!.getHttpServer()).get('/causes/education?language=hi').expect(200);
    await request(app!.getHttpServer()).get('/organisations?language=hi').expect(200);
    await request(app!.getHttpServer()).get('/organisations/seva?language=hi').expect(200);
    await request(app!.getHttpServer()).get('/beneficiaries?causeId=c-1&year=2026&search=student&sort=name').expect(200);
    await request(app!.getHttpServer()).get('/beneficiaries/b-1').expect(200);

    expect(causes.findAll).toHaveBeenCalledWith('hi');
    expect(organisations.findAll).toHaveBeenCalledWith('hi');
    expect(beneficiaries.findAll).toHaveBeenCalledWith({
      causeId: 'c-1', year: 2026, search: 'student', sort: 'name',
    });
  });

  it('routes authenticated identity resolution and admin dashboard access', async () => {
    auth.getCurrentUser.mockResolvedValue({ id: 'user-1', role: 'USER' });
    dashboard.getSummary.mockResolvedValue({ causes: 3, organisations: 2 });

    await request(app!.getHttpServer()).get('/auth/me').expect(200).expect({ id: 'user-1', role: 'USER' });
    await request(app!.getHttpServer()).get('/admin/dashboard').expect(200).expect({ causes: 3, organisations: 2 });

    expect(auth.getCurrentUser).toHaveBeenCalledWith(expect.objectContaining({ uid: 'firebase-1' }));
    expect(dashboard.getSummary).toHaveBeenCalled();
  });

  it('routes operational health and validates client health events at the HTTP boundary', async () => {
    health.checkDatabase.mockResolvedValue('ok');
    health.recordEvent.mockResolvedValue(undefined);
    health.getSummary.mockResolvedValue({ status: 'ok' });

    await request(app!.getHttpServer())
      .get('/platform-health')
      .expect(200)
      .expect({ status: 'ok', service: 'avijit-sahyog-api', database: 'ok' });

    await request(app!.getHttpServer())
      .post('/platform-health/client-events')
      .send({
        clientId: '01234567-89ab-cdef-0123-456789abcdef',
        sessionId: 'fedcba98-7654-3210-fedc-ba9876543210',
        type: 'APP_ERROR',
        message: 'test',
      })
      .expect(201)
      .expect({ status: 'recorded' });

    await request(app!.getHttpServer())
      .post('/platform-health/client-events')
      .send({ clientId: 'bad', sessionId: 'bad', type: 'APP_ERROR' })
      .expect(400);

    expect(health.recordEvent).toHaveBeenCalled();
  });
});
