import { ConflictException } from '@nestjs/common';
import { AdminUsersService } from './admin-users.service';

describe('AdminUsersService', () => {
  const prisma = {
    user: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
    $transaction: jest.fn(),
  } as any;

  beforeEach(() => jest.clearAllMocks());

  it('promotes a user and records the role change in the same transaction', async () => {
    const actor = { id: 'actor-1' };
    const target = { id: 'target-1', role: 'USER' };
    const updated = { id: 'target-1', role: 'ADMIN' };
    const tx = {
      user: { update: jest.fn().mockResolvedValue(updated) },
      auditLog: { create: jest.fn().mockResolvedValue({ id: 'audit-1' }) },
    };
    prisma.user.findUnique
      .mockResolvedValueOnce(actor)
      .mockResolvedValueOnce(target);
    prisma.$transaction.mockImplementation(async (callback: any) => callback(tx));

    const service = new AdminUsersService(prisma);
    const result = await service.changeRoleToAdmin('target-1', 'firebase-actor');

    expect(result).toEqual(updated);
    expect(tx.user.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'target-1' },
      data: { role: 'ADMIN' },
    }));
    expect(tx.auditLog.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        action: 'USER_ROLE_CHANGED',
        actorUserId: 'actor-1',
        targetUserId: 'target-1',
        fromRole: 'USER',
        toRole: 'ADMIN',
      }),
    }));
  });

  it('rejects promoting an existing admin', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({ id: 'actor-1' })
      .mockResolvedValueOnce({ id: 'target-1', role: 'ADMIN' });

    const service = new AdminUsersService(prisma);

    await expect(
      service.changeRoleToAdmin('target-1', 'firebase-actor'),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});
