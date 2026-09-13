import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminDashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary() {
    const [causes, organisations, beneficiaries] = await Promise.all([
      this.count(this.prisma.cause),
      this.count(this.prisma.organisation),
      this.count(this.prisma.beneficiary),
    ]);
    return { causes, organisations, beneficiaries };
  }

  async getAnalytics() {
    const [audience, activity, trend] = await Promise.all([
      this.prisma.$queryRaw<Array<{dau: bigint; wau: bigint; mau: bigint; newUsers: bigint; returningUsers: bigint}>>`WITH active AS (SELECT DISTINCT "clientId" FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days'), first_seen AS (SELECT "clientId", MIN("createdAt") AS "firstSeenAt" FROM "AnalyticsEvent" GROUP BY "clientId") SELECT (SELECT COUNT(DISTINCT "clientId") FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '1 day') AS dau, (SELECT COUNT(DISTINCT "clientId") FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '7 days') AS wau, (SELECT COUNT(DISTINCT "clientId") FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days') AS mau, (SELECT COUNT(*) FROM active a JOIN first_seen f USING ("clientId") WHERE f."firstSeenAt" >= NOW() - INTERVAL '30 days') AS "newUsers", (SELECT COUNT(*) FROM active a JOIN first_seen f USING ("clientId") WHERE f."firstSeenAt" < NOW() - INTERVAL '30 days') AS "returningUsers"`,
      this.prisma.$queryRaw<Array<{sessions: bigint; screenViews: bigint; interactions: bigint; navigationEvents: bigint}>>`SELECT COUNT(DISTINCT "sessionId") AS sessions, COUNT(*) FILTER (WHERE "eventName" = 'screen_view') AS "screenViews", COUNT(*) FILTER (WHERE "eventName" = 'ui_interaction') AS interactions, COUNT(*) FILTER (WHERE "eventName" = 'navigation_select') AS "navigationEvents" FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days'`,
      this.prisma.$queryRaw<Array<{day: Date; activeUsers: bigint; sessions: bigint; screenViews: bigint; interactions: bigint}>>`SELECT DATE_TRUNC('day', "createdAt") AS day, COUNT(DISTINCT "clientId") AS "activeUsers", COUNT(DISTINCT "sessionId") AS sessions, COUNT(*) FILTER (WHERE "eventName" = 'screen_view') AS "screenViews", COUNT(*) FILTER (WHERE "eventName" IN ('ui_interaction', 'navigation_select')) AS interactions FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '14 days' GROUP BY DATE_TRUNC('day', "createdAt") ORDER BY day ASC`,
    ]);
    const a = audience[0] ?? {dau: 0n, wau: 0n, mau: 0n, newUsers: 0n, returningUsers: 0n};
    const b = activity[0] ?? {sessions: 0n, screenViews: 0n, interactions: 0n, navigationEvents: 0n};
    return { periodDays: 30, dau: Number(a.dau), wau: Number(a.wau), mau: Number(a.mau), newUsers: Number(a.newUsers), returningUsers: Number(a.returningUsers), sessions: Number(b.sessions), screenViews: Number(b.screenViews), interactions: Number(b.interactions), navigationEvents: Number(b.navigationEvents), engagementTrend: trend.map(r => ({date: r.day.toISOString().slice(0,10), activeUsers: Number(r.activeUsers), sessions: Number(r.sessions), screenViews: Number(r.screenViews), interactions: Number(r.interactions)})) };
  }

  async getAdvancedAnalytics() {
    const [retention, engagementCohorts, featureAdoption, language, device, city] = await Promise.all([
      this.prisma.$queryRaw<Array<{cohort: Date; users: bigint; day1: bigint; day7: bigint; day30: bigint}>>`
        WITH first_seen AS (
          SELECT "clientId", MIN("createdAt") AS first_seen FROM "AnalyticsEvent" GROUP BY "clientId"
        ), cohorts AS (
          SELECT "clientId", DATE_TRUNC('week', first_seen) AS cohort, first_seen FROM first_seen
          WHERE first_seen >= NOW() - INTERVAL '12 weeks'
        )
        SELECT cohort, COUNT(*) AS users,
          COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM "AnalyticsEvent" e WHERE e."clientId" = cohorts."clientId" AND e."createdAt" >= cohorts.first_seen + INTERVAL '1 day' AND e."createdAt" < cohorts.first_seen + INTERVAL '2 days')) AS day1,
          COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM "AnalyticsEvent" e WHERE e."clientId" = cohorts."clientId" AND e."createdAt" >= cohorts.first_seen + INTERVAL '7 days' AND e."createdAt" < cohorts.first_seen + INTERVAL '8 days')) AS day7,
          COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM "AnalyticsEvent" e WHERE e."clientId" = cohorts."clientId" AND e."createdAt" >= cohorts.first_seen + INTERVAL '30 days' AND e."createdAt" < cohorts.first_seen + INTERVAL '31 days')) AS day30
        FROM cohorts GROUP BY cohort ORDER BY cohort ASC`,
      this.prisma.$queryRaw<Array<{cohort: Date; users: bigint; sessions: bigint; interactions: bigint}>>`
        WITH first_seen AS (SELECT "clientId", MIN("createdAt") AS first_seen FROM "AnalyticsEvent" GROUP BY "clientId")
        SELECT DATE_TRUNC('week', f.first_seen) AS cohort,
          COUNT(DISTINCT f."clientId") AS users,
          COUNT(DISTINCT e."sessionId") AS sessions,
          COUNT(*) FILTER (WHERE e."eventName" IN ('ui_interaction', 'navigation_select')) AS interactions
        FROM first_seen f JOIN "AnalyticsEvent" e ON e."clientId" = f."clientId"
        WHERE f.first_seen >= NOW() - INTERVAL '12 weeks' AND e."createdAt" >= f.first_seen AND e."createdAt" < f.first_seen + INTERVAL '7 days'
        GROUP BY DATE_TRUNC('week', f.first_seen) ORDER BY cohort ASC`,
      this.prisma.$queryRaw<Array<{feature: string; users: bigint; events: bigint}>>`
        SELECT COALESCE(NULLIF("screenName", ''), 'unknown') AS feature, COUNT(DISTINCT "clientId") AS users, COUNT(*) AS events
        FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days' AND "eventName" = 'screen_view'
        GROUP BY COALESCE(NULLIF("screenName", ''), 'unknown') ORDER BY users DESC, feature ASC LIMIT 50`,
      this.prisma.$queryRaw<Array<{segment: string; users: bigint; events: bigint}>>`SELECT COALESCE(NULLIF("language", ''), 'unknown') AS segment, COUNT(DISTINCT "clientId") AS users, COUNT(*) AS events FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days' GROUP BY COALESCE(NULLIF("language", ''), 'unknown') ORDER BY users DESC, segment ASC`,
      this.prisma.$queryRaw<Array<{segment: string; users: bigint; events: bigint}>>`SELECT COALESCE(NULLIF("deviceType", ''), 'unknown') AS segment, COUNT(DISTINCT "clientId") AS users, COUNT(*) AS events FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days' GROUP BY COALESCE(NULLIF("deviceType", ''), 'unknown') ORDER BY users DESC, segment ASC`,
      this.prisma.$queryRaw<Array<{segment: string; users: bigint; events: bigint}>>`SELECT COALESCE(NULLIF("city", ''), 'unknown') AS segment, COUNT(DISTINCT "clientId") AS users, COUNT(*) AS events FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days' GROUP BY COALESCE(NULLIF("city", ''), 'unknown') ORDER BY users DESC, segment ASC LIMIT 100`,
    ]);

    const mau = await this.prisma.$queryRaw<Array<{users: bigint}>>`SELECT COUNT(DISTINCT "clientId") AS users FROM "AnalyticsEvent" WHERE "createdAt" >= NOW() - INTERVAL '30 days'`;
    const totalMau = Number(mau[0]?.users ?? 0n);
    const segment = (rows: Array<{segment: string; users: bigint; events: bigint}>) => rows.map(row => ({segment: row.segment, users: Number(row.users), events: Number(row.events), sharePercent: totalMau === 0 ? 0 : Math.round((Number(row.users) / totalMau) * 1000) / 10}));
    const percent = (value: bigint, total: bigint) => total === 0n ? 0 : Math.round((Number(value) / Number(total)) * 1000) / 10;

    return {
      retention: retention.map(row => ({cohort: row.cohort.toISOString().slice(0, 10), users: Number(row.users), day1Percent: percent(row.day1, row.users), day7Percent: percent(row.day7, row.users), day30Percent: percent(row.day30, row.users)})),
      engagementCohorts: engagementCohorts.map(row => ({cohort: row.cohort.toISOString().slice(0, 10), users: Number(row.users), sessions: Number(row.sessions), interactions: Number(row.interactions), sessionsPerUser: row.users === 0n ? 0 : Math.round((Number(row.sessions) / Number(row.users)) * 100) / 100})),
      featureAdoption: featureAdoption.map(row => ({feature: row.feature, users: Number(row.users), events: Number(row.events), adoptionPercent: totalMau === 0 ? 0 : Math.round((Number(row.users) / totalMau) * 1000) / 10})),
      segmentation: { city: segment(city), language: segment(language), device: segment(device) },
      cohortUsers: retention.reduce((sum, row) => sum + Number(row.users), 0),
      mau: totalMau,
      warehouse: { provider: 'postgresql', bigQueryReady: true, exportGrain: 'analytics_event' },
    };
  }

  private async count(model: {count(args: {where?: {isActive: boolean}}): Promise<number>}) {
    const [total, active] = await Promise.all([model.count({}), model.count({where: {isActive: true}})]);
    return {total, active, inactive: total - active};
  }
}
