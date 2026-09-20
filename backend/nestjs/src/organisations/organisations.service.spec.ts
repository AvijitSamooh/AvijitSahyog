import { ConflictException } from '@nestjs/common';

import { OrganisationsService } from './organisations.service';

describe('OrganisationsService.removeOrDeactivate', () => {
  const prisma = {
    organisation: { findUnique: jest.fn(), update: jest.fn(), delete: jest.fn() },
    donationAllocation: { count: jest.fn() },
    beneficiary: { count: jest.fn() },
    user: { findUnique: jest.fn() },
    $transaction: jest.fn(),
  };

  const organisation = {
    id: 'org-1',
    slug: 'help',
    translations: [{ language: { code: 'en' }, name: 'Help Organisation' }],
  };

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.organisation.findUnique.mockResolvedValue(organisation);
    prisma.user.findUnique.mockResolvedValue({ id: 'actor-1' });
  });

  function service() {
    return new OrganisationsService(prisma as never);
  }

  it('deactivates an organisation with historical allocations instead of throwing a conflict', async () => {
    prisma.donationAllocation.count.mockResolvedValue(1);
    prisma.beneficiary.count.mockResolvedValue(0);
    const tx = {
      organisation: { update: jest.fn().mockResolvedValue({ id: 'org-1', isActive: false }) },
      auditLog: { create: jest.fn().mockResolvedValue({ id: 'audit-1' }) },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: typeof tx) => unknown) => callback(tx));

    await expect(service().removeOrDeactivate('org-1', 'firebase-1')).resolves.toEqual({
      id: 'org-1',
      deleted: false,
      deactivated: true,
    });

    expect(tx.organisation.update).toHaveBeenCalledWith({
      where: { id: 'org-1' },
      data: { isActive: false },
    });
    expect(tx.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        actorUserId: 'actor-1',
        metadata: expect.objectContaining({
          eventType: 'ORGANISATION_DEACTIVATED',
          reason: 'DEPENDENCY_PROTECTION',
          donationAllocationCount: 1,
          beneficiaryCount: 0,
        }),
      }),
    });
  });

  it('deactivates when beneficiary history exists too', async () => {
    prisma.donationAllocation.count.mockResolvedValue(0);
    prisma.beneficiary.count.mockResolvedValue(2);
    const tx = {
      organisation: { update: jest.fn().mockResolvedValue({ id: 'org-1', isActive: false }) },
      auditLog: { create: jest.fn().mockResolvedValue({ id: 'audit-1' }) },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: typeof tx) => unknown) => callback(tx));

    await expect(service().removeOrDeactivate('org-1', 'firebase-1')).resolves.toEqual({
      id: 'org-1',
      deleted: false,
      deactivated: true,
    });
    expect(tx.organisation.update).toHaveBeenCalled();
  });

  it('permanently deletes an organisation with no historical dependencies', async () => {
    prisma.donationAllocation.count.mockResolvedValue(0);
    prisma.beneficiary.count.mockResolvedValue(0);
    const tx = {
      organisation: { delete: jest.fn().mockResolvedValue({ id: 'org-1' }) },
      auditLog: { create: jest.fn().mockResolvedValue({ id: 'audit-1' }) },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: typeof tx) => unknown) => callback(tx));

    await expect(service().removeOrDeactivate('org-1', 'firebase-1')).resolves.toEqual({
      id: 'org-1',
      deleted: true,
      deactivated: false,
    });

    expect(tx.organisation.delete).toHaveBeenCalledWith({ where: { id: 'org-1' } });
    expect(tx.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        metadata: expect.objectContaining({ eventType: 'ORGANISATION_DELETED' }),
      }),
    });
  });

  it('rejects the mutation when the authenticated administrator is missing', async () => {
    prisma.donationAllocation.count.mockResolvedValue(0);
    prisma.beneficiary.count.mockResolvedValue(0);
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(service().removeOrDeactivate('org-1', 'unknown')).rejects.toBeInstanceOf(
      ConflictException,
    );
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});
