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

  describe('health', () => {
    it('should return a healthy status when the database check succeeds', async () => {
      await expect(appController.getHealth()).resolves.toEqual({
        status: 'ok',
        service: 'avijit-sahyog-api',
        database: 'ok',
      });
    });

    it('should return an error status when the database check fails', async () => {
      queryRaw.mockRejectedValue(new Error('database unavailable'));

      await expect(appController.getHealth()).resolves.toEqual({
        status: 'error',
        service: 'avijit-sahyog-api',
        database: 'error',
      });
    });
  });
});
