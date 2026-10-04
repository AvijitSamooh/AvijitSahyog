import { Injectable, Optional } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirestorePlatformHealthService } from './firestore-platform-health.service';
import { FirebaseService } from '../firebase/firebase.service';

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

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly firestoreHealth?: FirestorePlatformHealthService,
    @Optional() private readonly firebase?: FirebaseService,
  ) {}

  async recordEvent(input: RecordHealthEventInput): Promise<void> {
    try {
      if (this.firestoreHealth) {
        await this.firestoreHealth.recordEvent(input);
        return;
      }
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
    if (this.firebase) {
      const now = new Date();
      const last24Hours = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      const snapshot = await this.firebase.db
        .collection('platformHealthEvents')
        .where('createdAt', '>=', last7Days)
        .orderBy('createdAt', 'desc')
        .limit(5000)
        .get();

      const events = snapshot.docs.map((doc) => {
        const data = doc.data();
        const createdAt = data.createdAt?.toDate?.() ?? new Date(String(data.createdAt));
        return {
          id: doc.id,
          type: String(data.type ?? ''),
          statusCode: data.statusCode == null ? null : Number(data.statusCode),
          route: data.route == null ? null : String(data.route),
          method: data.method == null ? null : String(data.method),
          message: data.message == null ? null : String(data.message),
          createdAt,
        };
      });
      const recent24 = events.filter((event) => event.createdAt >= last24Hours);
      const countType = (items: typeof events, type: string) =>
        items.filter((event) => event.type === type).length;
      const byType7d = Object.fromEntries(
        [...new Set(events.map((event) => event.type))].map((type) => [
          type,
          countType(events, type),
        ]),
      );
      const database = await this.checkDatabase();

      return {
        status: database === 'ok' ? 'healthy' : 'degraded',
        api: { status: 'ok', uptimeSeconds: Math.floor((Date.now() - this.startedAt.getTime()) / 1000) },
        database,
        deployment: {
          environment: process.env.NODE_ENV ?? 'unknown',
          version: process.env.APP_VERSION ?? 'unknown',
          deploymentId: process.env.DEPLOYMENT_ID ?? 'unknown',
          gitSha: process.env.GIT_SHA ?? 'unknown',
          deployedAt: process.env.DEPLOYED_AT ?? null,
        },
        errors24h: countType(recent24, 'HTTP_ERROR'),
        authFailures24h: countType(recent24, 'AUTH_FAILURE'),
        uploadFailures24h: countType(recent24, 'UPLOAD_FAILURE'),
        appErrors24h: countType(recent24, 'APP_ERROR'),
        crashes24h: countType(recent24, 'APP_CRASH'),
        last7Days: byType7d,
        recentEvents: events.slice(0, 25).map((event) => ({ ...event, createdAt: event.createdAt.toISOString() })),
      };
    }

    const now = Date.now();
    const last24Hours = new Date(now - 24 * 60 * 60 * 1000);
    const last7Days = new Date(now - 7 * 24 * 60 * 60 * 1000);

    const [database, recent, byType24h, byType7d] = await Promise.all([
      this.checkDatabase(),
      this.prisma.$queryRaw<Array<{ id: string; type: string; statusCode: number | null; route: string | null; method: string | null; message: string | null; createdAt: Date }>>`
        SELECT "id", "type", "statusCode", "route", "method", "message", "createdAt"
        FROM "PlatformHealthEvent" WHERE "createdAt" >= ${last7Days}
        ORDER BY "createdAt" DESC LIMIT 25`,
      this.prisma.$queryRaw<Array<{ type: string; count: bigint }>>`
        SELECT "type", COUNT(*)::bigint AS "count" FROM "PlatformHealthEvent"
        WHERE "createdAt" >= ${last24Hours} GROUP BY "type" ORDER BY "count" DESC`,
      this.prisma.$queryRaw<Array<{ type: string; count: bigint }>>`
        SELECT "type", COUNT(*)::bigint AS "count" FROM "PlatformHealthEvent"
        WHERE "createdAt" >= ${last7Days} GROUP BY "type" ORDER BY "count" DESC`,
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
      if (this.firebase) {
        await this.firebase.db.collection('platformSettings').doc('downtime').get();
      } else {
        await this.prisma.$queryRaw`SELECT 1`;
      }
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
