import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { FirebaseService } from './firebase/firebase.service';

describe('AppController', () => {
  let appController: AppController;
  let get: jest.Mock;

  beforeEach(async () => {
    get = jest.fn().mockResolvedValue({ exists: true });

    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: FirebaseService,
          useValue: {
            db: {
              collection: jest.fn(() => ({ doc: jest.fn(() => ({ get })) })),
            },
          },
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('liveness health', () => {
    it('returns healthy status without querying the database', async () => {
      const health = await appController.getHealth();

      expect(health).toEqual({
        status: 'ok',
        service: 'avijit-sahyog-api',
        uptimeSeconds: expect.any(Number),
        deployment: {
          environment: 'test',
          version: 'unknown',
          deploymentId: 'unknown',
          gitSha: 'unknown',
          deployedAt: null,
        },
      });
      expect(health.uptimeSeconds).toBeGreaterThanOrEqual(0);
      expect(get).not.toHaveBeenCalled();
    });
  });

  describe('database readiness', () => {
    it('returns healthy status when the database check succeeds', async () => {
      await expect(appController.getReadiness()).resolves.toEqual({
        status: 'ok',
        service: 'avijit-sahyog-api',
        database: 'ok',
      });
      expect(get).toHaveBeenCalledTimes(1);
    });

    it('returns safe Firebase diagnostics when the database check fails', async () => {
      const error = Object.assign(
        new Error('datastore unavailable: secret details'),
        { code: 'permission-denied' },
      );
      get.mockRejectedValue(error);

      await expect(appController.getReadiness()).rejects.toMatchObject({
        response: {
          status: 'error',
          service: 'avijit-sahyog-api',
          database: 'error',
          errorCode: 'permission-denied',
          errorType: 'Error',
          errorMessage: 'datastore unavailable: secret details',
        },
        status: 503,
      });
    });

    it('redacts private keys from the diagnostic message', async () => {
      const error = new Error(
        'credentials -----BEGIN PRIVATE KEY-----abc-----END PRIVATE KEY-----',
      );
      get.mockRejectedValue(error);

      await expect(appController.getReadiness()).rejects.toMatchObject({
        response: {
          errorMessage: 'credentials [redacted-key]',
        },
      });
    });
  });
});
