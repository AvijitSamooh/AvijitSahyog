import { ConflictException } from '@nestjs/common';

import { AdminOrganisationsController } from './admin-organisations.controller';

describe('AdminOrganisationsController media, create and deletion endpoints', () => {
  const service = {
    listMedia: jest.fn(),
    attachMedia: jest.fn(),
    updateMedia: jest.fn(),
    removeMedia: jest.fn(),
    findOneForAdmin: jest.fn(),
    create: jest.fn(),
  };
  const prisma = {
    donationAllocation: { count: jest.fn() },
    beneficiary: { count: jest.fn() },
    user: { findUnique: jest.fn() },
    $transaction: jest.fn(),
  };
  const controller = new AdminOrganisationsController(service as never, prisma as never);

  beforeEach(() => jest.clearAllMocks());

  it('delegates listing media', async () => {
    service.listMedia.mockResolvedValue([]);
    await controller.listMedia('org-1');
    expect(service.listMedia).toHaveBeenCalledWith('org-1');
  });

  it('delegates attaching media', async () => {
    const dto = { mediaId: 'media-1', purpose: 'GALLERY' as const };
    service.attachMedia.mockResolvedValue({ id: 'relation-1' });
    await expect(controller.attachMedia('org-1', dto)).resolves.toEqual({ id: 'relation-1' });
    expect(service.attachMedia).toHaveBeenCalledWith('org-1', dto);
  });

  it('delegates updating and removing media', async () => {
    const dto = { isPrimary: true };
    await controller.updateMedia('org-1', 'media-1', dto);
    await controller.removeMedia('org-1', 'media-1');
    expect(service.updateMedia).toHaveBeenCalledWith('org-1', 'media-1', dto);
    expect(service.removeMedia).toHaveBeenCalledWith('org-1', 'media-1');
  });

  it('delegates organisation creation to the service', async () => {
    const dto = {
      email: 'contact@example.org',
      translations: [{ languageCode: 'en', name: 'Help Organisation' }],
    };
    service.create.mockResolvedValue({ id: 'org-1', slug: 'help-organisation' });

    await expect(controller.create(dto)).resolves.toEqual({
      id: 'org-1',
      slug: 'help-organisation',
    });
    expect(service.create).toHaveBeenCalledWith(dto);
  });

  it('blocks deletion when the organisation has donation allocations', async () => {
    service.findOneForAdmin.mockResolvedValue({
      id: 'org-1',
      slug: 'help',
      translations: [],
    });
    prisma.donationAllocation.count.mockResolvedValue(1);
    prisma.beneficiary.count.mockResolvedValue(0);

    await expect(
      controller.remove('org-1', { user: { uid: 'firebase-1' } } as never),
    ).rejects.toBeInstanceOf(ConflictException);
    await expect(
      controller.remove('org-1', { user: { uid: 'firebase-1' } } as never),
    ).rejects.toThrow('Deactivate it instead');
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('blocks deletion when the organisation has beneficiary records', async () => {
    service.findOneForAdmin.mockResolvedValue({
      id: 'org-1',
      slug: 'help',
      translations: [],
    });
    prisma.donationAllocation.count.mockResolvedValue(0);
    prisma.beneficiary.count.mockResolvedValue(2);

    await expect(
      controller.remove('org-1', { user: { uid: 'firebase-1' } } as never),
    ).rejects.toThrow('2 beneficiary record(s)');
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('blocks deletion when both dependency types exist and reports both counts', async () => {
    service.findOneForAdmin.mockResolvedValue({
      id: 'org-1',
      slug: 'help',
      translations: [],
    });
    prisma.donationAllocation.count.mockResolvedValue(3);
    prisma.beneficiary.count.mockResolvedValue(4);

    await expect(
      controller.remove('org-1', { user: { uid: 'firebase-1' } } as never),
    ).rejects.toThrow('3 donation allocation(s) and 4 beneficiary record(s)');
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects deletion when the authenticated administrator record is missing', async () => {
    service.findOneForAdmin.mockResolvedValue({
      id: 'org-1',
      slug: 'help',
      translations: [],
    });
    prisma.donationAllocation.count.mockResolvedValue(0);
    prisma.beneficiary.count.mockResolvedValue(0);
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(
      controller.remove('org-1', { user: { uid: 'unknown' } } as never),
    ).rejects.toThrow('Administrator account was not found');
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('deletes an unused organisation and records the audit event', async () => {
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
    prisma.$transaction.mockImplementation(async (callback: (tx: typeof tx) => unknown) => callback(tx));

    await expect(
      controller.remove('org-1', { user: { uid: 'firebase-1' } } as never),
    ).resolves.toEqual({ id: 'org-1', deleted: true });

    expect(tx.organisation.delete).toHaveBeenCalledWith({ where: { id: 'org-1' } });
    expect(tx.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        action: 'USER_ROLE_CHANGED',
        actorUserId: 'actor-1',
        metadata: expect.objectContaining({
          eventType: 'ORGANISATION_DELETED',
          organisationId: 'org-1',
          organisationName: 'Help Organisation',
        }),
      }),
    });
  });
});
