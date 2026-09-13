import {
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
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

  function setupTransaction(updated: any = { id: 'target-1', role: 'ADMIN' }) {
    const tx = {
      user: { update: jest.fn().mockResolvedValue(updated) },
      auditLog: { create: jest.fn().mockResolvedValue({ id: 'audit-1' }) },
    };
    prisma.$transaction.mockImplementation(async (callback: any) => callback(tx));
    return tx;
  }

  it('promotes a user and records the role change in the same transaction', async () => {
    const tx = setupTransaction();
    prisma.user.findUnique
      .mockResolvedValueOnce({ id: 'actor-1', role: 'SUPER_ADMIN' })
      .mockResolvedValueOnce({ id: 'target-1', role: 'USER' });

    const service = new AdminUsersService(prisma);
    const result = await service.changeRole('target-1', 'firebase-actor', 'ADMIN');

    expect(result).toEqual({ id: 'target-1', role: 'ADMIN' });
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
        metadata: { reason: 'admin_promotion' },
      }),
    }));
  });

  it('demotes an admin and records the role change in the same transaction', async () => {
    const tx = setupTransaction({ id: 'target-1', role: 'USER' });
    prisma.user.findUnique
      .mockResolvedValueOnce({ id: 'actor-1', role: 'SUPER_ADMIN' })
      .mockResolvedValueOnce({ id: 'target-1', role: 'ADMIN' });

    const service = new AdminUsersService(prisma);
    const result = await service.changeRole('target-1', 'firebase-actor', 'USER');

    expect(result).toEqual({ id: 'target-1', role: 'USER' });
    expect(tx.user.update).toHaveBeenCalledWith(expect.objectContaining({
      data: { role: 'USER' },
    }));
    expect(tx.auditLog.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        fromRole: 'ADMIN',
        toRole: 'USER',
        metadata: { reason: 'admin_demotion' },
      }),
    }));
  });

  it('rejects unsupported target roles', async () => {
    const service = new AdminUsersService(prisma);

    await expect(
      service.changeRole('target-1', 'firebase-actor', 'SUPER_ADMIN'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('rejects changing a super admin role', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({ id: 'actor-1', role: 'SUPER_ADMIN' })
      .mockResolvedValueOnce({ id: 'target-1', role: 'SUPER_ADMIN' });

    const service = new AdminUsersService(prisma);

    await expect(
      service.changeRole('target-1', 'firebase-actor', 'ADMIN'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects changing the actor own role', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({ id: 'actor-1', role: 'SUPER_ADMIN' })
      .mockResolvedValueOnce({ id: 'actor-1', role: 'ADMIN' });

    const service = new AdminUsersService(prisma);

    await expect(
      service.changeRole('actor-1', 'firebase-actor', 'USER'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects promoting an existing admin', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({ id: 'actor-1', role: 'SUPER_ADMIN' })
      .mockResolvedValueOnce({ id: 'target-1', role: 'ADMIN' });

    const service = new AdminUsersService(prisma);

    await expect(
      service.changeRole('target-1', 'firebase-actor', 'ADMIN'),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects demoting an existing regular user', async () => {
    prisma.user.findUnique
      .mockResolvedValueOnce({ id: 'actor-1', role: 'SUPER_ADMIN' })
      .mockResolvedValueOnce({ id: 'target-1', role: 'USER' });

    const service = new AdminUsersService(prisma);

    await expect(
      service.changeRole('target-1', 'firebase-actor', 'USER'),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});
