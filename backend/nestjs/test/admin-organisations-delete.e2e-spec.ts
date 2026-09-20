import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';

import { AdminGuard } from '../src/auth/admin.guard';
import { AdminOrganisationsController } from '../src/organisations/admin-organisations.controller';
import { OrganisationsService } from '../src/organisations/organisations.service';

describe('Admin organisation deletion HTTP route', () => {
  let app: INestApplication | undefined;

  const service = {
    removeOrDeactivate: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const moduleRef = await Test.createTestingModule({
      controllers: [AdminOrganisationsController],
      providers: [
        { provide: OrganisationsService, useValue: service },
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

  it('deactivates an organisation with historical dependencies instead of returning a conflict', async () => {
    service.removeOrDeactivate.mockResolvedValue({
      id: 'org-1',
      deleted: false,
      deactivated: true,
    });

    await request(app!.getHttpServer())
      .delete('/admin/organisations/org-1')
      .expect(200)
      .expect({ id: 'org-1', deleted: false, deactivated: true });

    expect(service.removeOrDeactivate).toHaveBeenCalledWith('org-1', 'firebase-1');
  });

  it('reaches the deletion handler for an unused organisation', async () => {
    service.removeOrDeactivate.mockResolvedValue({
      id: 'org-1',
      deleted: true,
      deactivated: false,
    });

    await request(app!.getHttpServer())
      .delete('/admin/organisations/org-1')
      .expect(200)
      .expect({ id: 'org-1', deleted: true, deactivated: false });

    expect(service.removeOrDeactivate).toHaveBeenCalledWith('org-1', 'firebase-1');
  });
});
