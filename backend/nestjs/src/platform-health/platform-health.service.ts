import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type PlatformHealthEventType =
  | 'HTTP_ERROR'
  | 'AUTH_FAILURE'
  | 'UPLOAD_FAILURE'
  | 'APP_ERROR'
  | 'APP_CRASH';

export type RecordHealthEventInput = {
  type: PlatformHealthEventType;
  statusCode?: number;
  route?: string;
  method?: string;
  message?: string;
  metadata?: Record<string, unknown>;
};

@Injectable()
export class PlatformHealthService {
  private readonly startedAt = new Date();

  constructor(private readonly prisma: PrismaService) {}

  async recordEvent(input: RecordHealthEventInput): Promise<void> {
    try {
      await this.prisma.$executeRaw`
        INSERT INTO "PlatformHealthEvent"
          ("type", "statusCode", "route", "method", "message", "metadata")
        VALUES
          (${input.type}, ${input.statusCode ?? null}, ${this.sanitizeRoute(input.route)},
           ${input.method ?? null}, ${this.sanitizeMessage(input.message)},
           ${input.metadata ? JSON.stringify(input.metadata) : null}::jsonb)
      `;
    } catch (_) {
      // Health telemetry must never make the original request fail.
    }
  }

  async getSummary() {
    const now = Date.now();
    const last24Hours = new Date(now - 24 * 60 * 60 * 1000);
    const last7Days = new Date(now - 7 * 24 * 60 * 60 * 1000);

    const [database, recent, byType24h, byType7d] = await Promise.all([
      this.checkDatabase(),
      this.prisma.$queryRaw<Array<{
        id: string;
        type: string;
        statusCode: number | null;
        route: string | null;
        method: string | null;
        message: string | null;
        createdAt: Date;
      }>>`
        SELECT "id", "type", "statusCode", "route", "method", "message", "createdAt"
        FROM "PlatformHealthEvent"
        WHERE "createdAt" >= ${last7Days}
        ORDER BY "createdAt" DESC
        LIMIT 25
      `,
      this.prisma.$queryRaw<Array<{ type: string; count: bigint }>>`
        SELECT "type", COUNT(*)::bigint AS "count"
        FROM "PlatformHealthEvent"
        WHERE "createdAt" >= ${last24Hours}
        GROUP BY "type"
        ORDER BY "count" DESC
      `,
      this.prisma.$queryRaw<Array<{ type: string; count: bigint }>>`
        SELECT "type", COUNT(*)::bigint AS "count"
        FROM "PlatformHealthEvent"
        WHERE "createdAt" >= ${last7Days}
        GROUP BY "type"
        ORDER BY "count" DESC
      `,
    ]);

    return {
      status: database === 'ok' ? 'healthy' : 'degraded',
      api: { status: 'ok', uptimeSeconds: Math.floor((now - this.startedAt.getTime()) / 1000) },
      database,
      deployment: {
        environment: process.env.NODE_ENV ?? 'unknown',
        version: process.env.APP_VERSION ?? 'unknown',
        deploymentId: process.env.DEPLOYMENT_ID ?? 'unknown',
        gitSha: process.env.GIT_SHA ?? 'unknown',
        deployedAt: process.env.DEPLOYED_AT ?? null,
      },
      errors24h: this.countType(byType24h, 'HTTP_ERROR'),
      authFailures24h: this.countType(byType24h, 'AUTH_FAILURE'),
      uploadFailures24h: this.countType(byType24h, 'UPLOAD_FAILURE'),
      appErrors24h: this.countType(byType24h, 'APP_ERROR'),
      crashes24h: this.countType(byType24h, 'APP_CRASH'),
      last7Days: Object.fromEntries(byType7d.map((row) => [row.type, Number(row.count)])),
      recentEvents: recent.map((event) => ({ ...event, createdAt: event.createdAt.toISOString() })),
    };
  }

  async checkDatabase(): Promise<'ok' | 'error'> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return 'ok';
    } catch (_) {
      return 'error';
    }
  }

  private countType(rows: Array<{ type: string; count: bigint }>, type: string): number {
    return Number(rows.find((row) => row.type === type)?.count ?? 0);
  }

  private sanitizeRoute(route?: string): string | null {
    if (!route) return null;
    return route.split('?')[0].slice(0, 200);
  }

  private sanitizeMessage(message?: string): string | null {
    if (!message) return null;
    return message.replace(/\s+/g, ' ').slice(0, 500);
  }
}
