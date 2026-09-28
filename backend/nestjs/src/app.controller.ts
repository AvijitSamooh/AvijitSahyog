import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';

@Controller('health')
export class AppController {
  private readonly startedAt = new Date();

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Liveness endpoint.
   *
   * This endpoint intentionally does not touch Postgres so infrastructure
   * health checks (for example Render) do not keep the Neon compute active.
   */
  @Get()
  getHealth() {
    return {
      status: 'ok',
      service: 'avijit-sahyog-api',
      uptimeSeconds: Math.floor((Date.now() - this.startedAt.getTime()) / 1000),
      deployment: {
        environment: process.env.NODE_ENV ?? 'unknown',
        version: process.env.APP_VERSION ?? 'unknown',
        deploymentId: process.env.DEPLOYMENT_ID ?? 'unknown',
        gitSha: process.env.GIT_SHA ?? 'unknown',
        deployedAt: process.env.DEPLOYED_AT ?? null,
      },
    };
  }

  /**
   * Readiness endpoint.
   *
   * Use this when a caller explicitly needs to verify database readiness.
   * Unlike /health, this endpoint intentionally performs a database query.
   */
  @Get('ready')
  async getReadiness() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'ok',
        service: 'avijit-sahyog-api',
        database: 'ok',
      };
    } catch {
      throw new ServiceUnavailableException({
        status: 'error',
        service: 'avijit-sahyog-api',
        database: 'error',
      });
    }
  }
}
