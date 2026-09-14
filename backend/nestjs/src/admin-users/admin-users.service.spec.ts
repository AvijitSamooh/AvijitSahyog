import {
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { AdminUsersService } from './admin-users.service';

describe('AdminUsersService', () => {
  const prisma = {
    user: {
      count: jest.fn(),
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
    prisma.$transaction.mockImplementation(async (operation: any) => {
      if (Array.isArray(operation)) return Promise.all(operation);
      return operation(tx);
    });
    return tx;
  }

  it('lists administrators with server-side search and pagination', async () => {
    prisma.user.count.mockResolvedValue(7);
    prisma.user.findMany.mockResolvedValue([
      {
        id: 'admin-1',
        email: 'nikita@example.com',
        displayName: 'Nikita',
        photoUrl: null,
        role: 'ADMIN',
        createdAt: new Date('2026-09-14T00:00:00Z'),
      },
    ]);

    const service = new AdminUsersService(prisma);
    const result = await service.listUsers({
      search: 'nikita',
      role: 'ADMIN',
      page: 2,
      pageSize: 3,
    });

    expect(result).toEqual({
      items: expect.any(Array),
      page: 2,
      pageSize: 3,
      total: 7,
    });
    expect(prisma.user.count).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ role: 'ADMIN' }),
    }));
    expect(prisma.user.findMany).toHaveBeenCalledWith(expect.objectContaining({
      skip: 3,
      take: 3,
      where: expect.objectContaining({
        role: 'ADMIN',
        OR: expect.arrayContaining([
          expect.objectContaining({ displayName: expect.any(Object) }),
          expect.objectContaining({ email: expect.any(Object) }),
        ]),
      }),
    }));
  });

  it('lists regular users for the make-admin search flow', async () => {
    prisma.user.count.mockResolvedValue(11);
    prisma.user.findMany.mockResolvedValue([]);

    const service = new AdminUsersService(prisma);
    const result = await service.listUsers({ role: 'USER', page: 1, pageSize: 10 });

    expect(result).toEqual({ items: [], page: 1, pageSize: 10, total: 11 });
    expect(prisma.user.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { role: 'USER' },
      take: 10,
    }));
  });

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
    expect(tx.user.update).toHaveBeenCalledWith(expect.objectContaining({ data: { role: 'USER' } }));
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
