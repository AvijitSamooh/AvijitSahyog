import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { FirebaseService } from './firebase/firebase.service';

@Controller('health')
export class AppController {
  private readonly startedAt = new Date();

  constructor(private readonly firebase: FirebaseService) {}

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
      await this.firebase.db.collection('platformSettings').doc('downtime').get();
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
