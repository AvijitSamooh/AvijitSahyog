import { ForbiddenException } from '@nestjs/common';

import { AdminGuard } from './admin.guard';

describe('AdminGuard', () => {
  const firebaseAuthGuard = { canActivate: jest.fn() };
  const prisma = { user: { findUnique: jest.fn() } };
  const guard = new AdminGuard(firebaseAuthGuard as never, prisma as never);

  beforeEach(() => jest.clearAllMocks());

  function context() {
    const request: any = { user: { uid: 'firebase-user-1' } };
    return {
      switchToHttp: () => ({ getRequest: () => request }),
    } as any;
  }

  it('allows authenticated administrators', async () => {
    firebaseAuthGuard.canActivate.mockResolvedValue(true);
    prisma.user.findUnique.mockResolvedValue({ role: 'ADMIN' });

    await expect(guard.canActivate(context())).resolves.toBe(true);
  });

  it('allows authenticated super administrators', async () => {
    firebaseAuthGuard.canActivate.mockResolvedValue(true);
    prisma.user.findUnique.mockResolvedValue({ role: 'SUPER_ADMIN' });

    await expect(guard.canActivate(context())).resolves.toBe(true);
  });

  it('rejects authenticated users without an elevated role', async () => {
    firebaseAuthGuard.canActivate.mockResolvedValue(true);
    prisma.user.findUnique.mockResolvedValue({ role: 'USER' });

    await expect(guard.canActivate(context())).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
