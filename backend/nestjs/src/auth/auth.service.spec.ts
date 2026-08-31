import { AuthService } from './auth.service';

describe('AuthService', () => {
  const prisma = { user: { upsert: jest.fn() } } as any;
  const service = new AuthService(prisma);

  beforeEach(() => jest.clearAllMocks());

  it('creates or updates the internal user from a verified Firebase identity', async () => {
    prisma.user.upsert.mockResolvedValue({
      id: 'user-1',
      email: 'user@example.com',
      displayName: 'Test User',
      photoUrl: null,
      role: 'USER',
      preferredLanguage: null,
    });

    await expect(service.getCurrentUser({
      uid: 'firebase-user-1',
      email: 'user@example.com',
      displayName: 'Test User',
    })).resolves.toEqual(expect.objectContaining({ role: 'USER' }));

    expect(prisma.user.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { firebaseUid: 'firebase-user-1' },
      create: expect.objectContaining({ firebaseUid: 'firebase-user-1' }),
    }));
  });
});
