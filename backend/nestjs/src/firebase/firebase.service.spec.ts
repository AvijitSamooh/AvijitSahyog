import { FirebaseService } from './firebase.service';

jest.mock('firebase-admin/app', () => ({
  cert: jest.fn((value) => value),
  getApps: jest.fn(() => []),
  initializeApp: jest.fn(() => ({ delete: jest.fn().mockResolvedValue(undefined) })),
}));

jest.mock('firebase-admin/firestore', () => ({
  getFirestore: jest.fn(() => ({ collection: jest.fn() })),
}));

describe('FirebaseService', () => {
  it('initializes Firestore through Firebase Admin', () => {
    const service = new FirebaseService();
    expect(service.db).toBeDefined();
  });

  it('can be destroyed cleanly', async () => {
    const service = new FirebaseService();
    await expect(service.onModuleDestroy()).resolves.toBeUndefined();
  });
});
