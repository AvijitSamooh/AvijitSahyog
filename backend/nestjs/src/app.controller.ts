import { Controller, Get, Logger, ServiceUnavailableException } from '@nestjs/common';
import { FirebaseService } from './firebase/firebase.service';

@Controller('health')
export class AppController {
  private readonly startedAt = new Date();
  private readonly logger = new Logger(AppController.name);

  constructor(private readonly firebase: FirebaseService) {}

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
   * On failure, expose only a bounded/redacted diagnostic string. This is
   * temporary operational detail for diagnosing production Firebase setup;
   * credentials, tokens and private keys are never returned.
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
      const firebaseError = error as { code?: unknown; message?: unknown };
      const errorCode =
        typeof firebaseError.code === 'string'
          ? firebaseError.code
          : 'unknown';
      const errorType =
        error instanceof Error ? error.constructor.name : 'UnknownError';
      const rawMessage =
        typeof firebaseError.message === 'string'
          ? firebaseError.message
          : 'unknown';
      const errorMessage = rawMessage
        .replace(
          /-----BEGIN PRIVATE KEY-----[\s\S]*?-----END PRIVATE KEY-----/g,
          '[redacted-key]',
        )
        .replace(/Bearer\s+[^\s]+/gi, 'Bearer [redacted]')
        .slice(0, 240);

      this.logger.error(
        `Firestore readiness check failed: code=${errorCode}; type=${errorType}; message=${errorMessage}`,
      );

      throw new ServiceUnavailableException({
        status: 'error',
        service: 'avijit-sahyog-api',
        database: 'error',
        errorCode,
        errorType,
        errorMessage,
      });
    }
  }
}
