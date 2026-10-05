import { Controller, Get, Logger, ServiceUnavailableException } from '@nestjs/common';
import { FirebaseService } from './firebase/firebase.service';

@Controller('health')
export class AppController {
  private readonly startedAt = new Date();
  private readonly logger = new Logger(AppController.name);

  constructor(private readonly firebase: FirebaseService) {}

  /**
   * Liveness endpoint.
   *
   * This endpoint intentionally does not touch Firestore so infrastructure
   * health checks remain lightweight and do not require a datastore read.
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
   * Readiness endpoint explicitly verifies Firestore availability.
   *
   * The response exposes only a safe Firebase error code/type, never the
   * exception message, credentials, tokens or document data. This makes
   * production configuration failures diagnosable without leaking secrets.
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
    } catch (error) {
      const firebaseError = error as { code?: unknown };
      const errorCode =
        typeof firebaseError.code === 'string'
          ? firebaseError.code
          : 'unknown';
      const errorType =
        error instanceof Error ? error.constructor.name : 'UnknownError';

      this.logger.error(
        `Firestore readiness check failed: code=${errorCode}; type=${errorType}`,
      );

      throw new ServiceUnavailableException({
        status: 'error',
        service: 'avijit-sahyog-api',
        database: 'error',
        errorCode,
        errorType,
      });
    }
  }
}
