import { Controller, Get } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';

@Controller('health')
export class AppController {
  private readonly startedAt = new Date();
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getHealth() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'ok',
        service: 'avijit-sahyog-api',
        database: 'ok',
        uptimeSeconds: Math.floor((Date.now() - this.startedAt.getTime()) / 1000),
        deployment: {
          environment: process.env.NODE_ENV ?? 'unknown',
          version: process.env.APP_VERSION ?? 'unknown',
          deploymentId: process.env.DEPLOYMENT_ID ?? 'unknown',
          gitSha: process.env.GIT_SHA ?? 'unknown',
          deployedAt: process.env.DEPLOYED_AT ?? null,
        },
      };
    } catch {
      return { status: 'error', service: 'avijit-sahyog-api', database: 'error' };
    }
  }
}
