import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';

import { AdminGuard } from '../src/auth/admin.guard';
import { AdminOrganisationsController } from '../src/organisations/admin-organisations.controller';
import { OrganisationsService } from '../src/organisations/organisations.service';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Admin organisation deletion HTTP route', () => {
  let app: INestApplication | undefined;

  const service = {
    findOneForAdmin: jest.fn(),
  };
  const prisma = {
    donationAllocation: { count: jest.fn() },
    beneficiary: { count: jest.fn() },
    user: { findUnique: jest.fn() },
    $transaction: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const moduleRef = await Test.createTestingModule({
      controllers: [AdminOrganisationsController],
      providers: [
        { provide: OrganisationsService, useValue: service },
        { provide: PrismaService, useValue: prisma },
      ],
    })
      .overrideGuard(AdminGuard)
      .useValue({
        canActivate: (context: any) => {
          context.switchToHttp().getRequest().user = { uid: 'firebase-1' };
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

  it('exposes DELETE /admin/organisations/:id and returns dependency conflict', async () => {
    service.findOneForAdmin.mockResolvedValue({
      id: 'org-1',
      slug: 'help',
      translations: [],
    });
    prisma.donationAllocation.count.mockResolvedValue(1);
    prisma.beneficiary.count.mockResolvedValue(0);

    const response = await request(app!.getHttpServer())
      .delete('/admin/organisations/org-1')
      .expect(409);

    expect(response.body.message).toContain('1 donation allocation(s)');
    expect(response.body.message).toContain('Deactivate it instead');
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('reaches the deletion handler for an unused organisation', async () => {
    service.findOneForAdmin.mockResolvedValue({
      id: 'org-1',
      slug: 'help',
      translations: [{ language: { code: 'en' }, name: 'Help Organisation' }],
    });
    prisma.donationAllocation.count.mockResolvedValue(0);
    prisma.beneficiary.count.mockResolvedValue(0);
    prisma.user.findUnique.mockResolvedValue({ id: 'actor-1' });

    const tx = {
      organisation: { delete: jest.fn().mockResolvedValue({ id: 'org-1' }) },
      auditLog: { create: jest.fn().mockResolvedValue({ id: 'audit-1' }) },
    };
    prisma.$transaction.mockImplementation(async (callback: (value: typeof tx) => unknown) => callback(tx));

    await request(app!.getHttpServer())
      .delete('/admin/organisations/org-1')
      .expect(200)
      .expect({ id: 'org-1', deleted: true });

    expect(tx.organisation.delete).toHaveBeenCalledWith({ where: { id: 'org-1' } });
  });
});
