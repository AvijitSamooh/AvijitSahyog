import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminDashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary() {
    const [causes, organisations, beneficiaries] = await Promise.all([this.count(this.prisma.cause), this.count(this.prisma.organisation), this.count(this.prisma.beneficiary)]);
    return { causes, organisations, beneficiaries };
  }

  async getAnalytics() {
    const [audience, activity, trend] = await Promise.all([
      this.prisma.$queryRaw<Array<{ dau: bigint; wau: bigint; mau: bigint; newUsers: bigint; returningUsers: bigint }>>`
        WITH active AS (SELECT DISTINCT "clientId" FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days'), first_seen AS (SELECT "clientId", MIN("createdAt") AS "firstSeenAt" FROM "AnalyticsEvent" GROUP BY "clientId")
        SELECT
          (SELECT COUNT(DISTINCT "clientId") FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '1 day') AS dau,
          (SELECT COUNT(DISTINCT "clientId") FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '7 days') AS wau,
          (SELECT COUNT(DISTINCT "clientId") FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days') AS mau,
          (SELECT COUNT(*) FROM active a JOIN first_seen f USING ("clientId") WHERE f."firstSeenAt" >= NOW() - INTERVAL '30 days') AS "newUsers",
          (SELECT COUNT(*) FROM active a JOIN first_seen f USING ("clientId") WHERE f."firstSeenAt" < NOW() - INTERVAL '30 days') AS "returningUsers"
      `,
      this.prisma.$queryRaw<Array<{ sessions: bigint; screenViews: bigint; interactions: bigint; navigationEvents: bigint }>>`
        SELECT COUNT(DISTINCT "sessionId") AS sessions, COUNT(*) FILTER (WHERE "eventName" = 'screen_view') AS "screenViews", COUNT(*) FILTER (WHERE "eventName" = 'ui_interaction') AS interactions, COUNT(*) FILTER (WHERE "eventName" = 'navigation_select') AS "navigationEvents"
        FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days'
      `,
      this.prisma.$queryRaw<Array<{ day: Date; activeUsers: bigint; sessions: bigint; screenViews: bigint; interactions: bigint }>>`
        SELECT DATE_TRUNC('day', "createdAt") AS day, COUNT(DISTINCT "clientId") AS "activeUsers", COUNT(DISTINCT "sessionId") AS sessions, COUNT(*) FILTER (WHERE "eventName" = 'screen_view') AS "screenViews", COUNT(*) FILTER (WHERE "eventName" IN ('ui_interaction', 'navigation_select')) AS interactions
        FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '14 days' GROUP BY DATE_TRUNC('day', "createdAt") ORDER BY day ASC
      `,
    ]);
    const a = audience[0] ?? { dau: BigInt(0), wau: BigInt(0), mau: BigInt(0), newUsers: BigInt(0), returningUsers: BigInt(0) };
    const b = activity[0] ?? { sessions: BigInt(0), screenViews: BigInt(0), interactions: BigInt(0), navigationEvents: BigInt(0) };
    return { periodDays: 30, dau: Number(a.dau), wau: Number(a.wau), mau: Number(a.mau), newUsers: Number(a.newUsers), returningUsers: Number(a.returningUsers), sessions: Number(b.sessions), screenViews: Number(b.screenViews), interactions: Number(b.interactions), navigationEvents: Number(b.navigationEvents), engagementTrend: trend.map((row) => ({ date: row.day.toISOString().slice(0, 10), activeUsers: Number(row.activeUsers), sessions: Number(row.sessions), screenViews: Number(row.screenViews), interactions: Number(row.interactions) })) };
  }

  private async count(model: { count(args: { where?: { isActive: boolean } }): Promise<number> }) {
    const [total, active] = await Promise.all([model.count({}), model.count({ where: { isActive: true } })]);
    return { total, active, inactive: total - active };
  }
}
