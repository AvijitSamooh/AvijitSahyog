import { AuthService } from './auth.service';

describe('AuthService', () => {
  const users = { upsertFromIdentity: jest.fn() };
  const service = new AuthService(users as never);

  beforeEach(() => jest.clearAllMocks());

  it('creates or updates the internal user from a verified Firebase identity', async () => {
    users.upsertFromIdentity.mockResolvedValue({
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
    })).resolves.toEqual({
      id: 'user-1',
      email: 'user@example.com',
      displayName: 'Test User',
      photoUrl: null,
      role: 'USER',
      preferredLanguage: null,
    });

    expect(users.upsertFromIdentity).toHaveBeenCalledWith({
      uid: 'firebase-user-1',
      email: 'user@example.com',
      displayName: 'Test User',
    });
  });
});
