import { ForbiddenException } from '@nestjs/common';

import { SuperAdminGuard } from './super-admin.guard';

describe('SuperAdminGuard', () => {
  const firebaseAuthGuard = { canActivate: jest.fn() };
  const prisma = { user: { findUnique: jest.fn() } };
  const guard = new SuperAdminGuard(
    firebaseAuthGuard as never,
    prisma as never,
  );

  beforeEach(() => jest.clearAllMocks());

  function context() {
    const request: any = { user: { uid: 'firebase-user-1' } };
    return {
      switchToHttp: () => ({ getRequest: () => request }),
    } as any;
  }

  it('allows a super administrator', async () => {
    firebaseAuthGuard.canActivate.mockResolvedValue(true);
    prisma.user.findUnique.mockResolvedValue({ role: 'SUPER_ADMIN' });

    await expect(guard.canActivate(context())).resolves.toBe(true);
  });

  it.each(['ADMIN', 'USER'])('rejects %s users', async (role) => {
    firebaseAuthGuard.canActivate.mockResolvedValue(true);
    prisma.user.findUnique.mockResolvedValue({ role });

    await expect(guard.canActivate(context())).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
