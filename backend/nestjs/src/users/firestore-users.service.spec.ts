import { Timestamp } from 'firebase-admin/firestore';
import { FirestoreUsersService, searchTokensFor } from './firestore-users.service';

describe('FirestoreUsersService', () => {
  it('creates prefix search tokens for names and email values', () => {
    expect(searchTokensFor(['Nikita Sharma', 'Nikita@example.com'])).toEqual(
      expect.arrayContaining(['n', 'ni', 'nik', 'nikita', 's', 'sh', 'sha', 'nikita']),
    );
  });

  it('creates a new user from a Firebase identity with USER role', async () => {
    const userRef = { id: 'user-1' };
    const querySnapshot = { empty: true, docs: [] };
    const transaction = {
      get: jest.fn().mockResolvedValue(querySnapshot),
      set: jest.fn(),
      update: jest.fn(),
    };
    const collection = {
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      doc: jest.fn().mockReturnValue(userRef),
    };
    const db = {
      collection: jest.fn().mockReturnValue(collection),
      runTransaction: jest.fn(async (callback: any) => callback(transaction)),
    };

    const service = new FirestoreUsersService({ db } as any);
    const result = await service.upsertFromIdentity({
      uid: 'firebase-1',
      email: 'user@example.com',
      displayName: 'Test User',
    });

    expect(result.role).toBe('USER');
    expect(transaction.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        firebaseUid: 'firebase-1',
        role: 'USER',
      }),
    );
  });

  it('updates an existing user without changing their role', async () => {
    const existing = {
      id: 'user-1',
      firebaseUid: 'firebase-1',
      email: 'old@example.com',
      displayName: 'Old',
      photoUrl: null,
      role: 'ADMIN',
      preferredLanguage: null,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      searchTokens: [],
    };
    const transaction = {
      get: jest.fn().mockResolvedValue({ empty: false, docs: [{ ref: {}, data: () => existing }] }),
      set: jest.fn(),
      update: jest.fn(),
    };
    const db = { runTransaction: jest.fn(async (callback: any) => callback(transaction)), collection: jest.fn() };
    const service = new FirestoreUsersService({ db } as any);

    const result = await service.upsertFromIdentity({
      uid: 'firebase-1',
      email: 'new@example.com',
      displayName: 'New',
    });

    expect(result.role).toBe('ADMIN');
    expect(transaction.update).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ email: 'new@example.com', displayName: 'New' }),
    );
  });
});
