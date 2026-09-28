import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { PrismaService } from './prisma/prisma.service';

describe('AppController', () => {
  let appController: AppController;
  let queryRaw: jest.Mock;

  beforeEach(async () => {
    queryRaw = jest.fn().mockResolvedValue([{ '?column?': 1 }]);

    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: PrismaService,
          useValue: {
            $queryRaw: queryRaw,
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
      expect(queryRaw).not.toHaveBeenCalled();
    });
  });

  describe('database readiness', () => {
    it('returns healthy status when the database check succeeds', async () => {
      await expect(appController.getReadiness()).resolves.toEqual({
        status: 'ok',
        service: 'avijit-sahyog-api',
        database: 'ok',
      });
      expect(queryRaw).toHaveBeenCalledTimes(1);
    });

    it('returns service unavailable when the database check fails', async () => {
      queryRaw.mockRejectedValue(new Error('database unavailable'));

      await expect(appController.getReadiness()).rejects.toMatchObject({
        response: {
          status: 'error',
          service: 'avijit-sahyog-api',
          database: 'error',
        },
        status: 503,
      });
    });
  });
});
