-- Store a privacy-conscious analytics event stream for the Super Admin dashboard.
CREATE TABLE "AnalyticsEvent" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "clientId" VARCHAR(64) NOT NULL,
    "sessionId" VARCHAR(64) NOT NULL,
    "eventName" VARCHAR(64) NOT NULL,
    "screenName" VARCHAR(64),
    "interactionType" VARCHAR(32),
    "target" VARCHAR(128),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AnalyticsEvent_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "AnalyticsEvent_createdAt_idx" ON "AnalyticsEvent"("createdAt");
CREATE INDEX "AnalyticsEvent_clientId_createdAt_idx" ON "AnalyticsEvent"("clientId", "createdAt");
CREATE INDEX "AnalyticsEvent_sessionId_createdAt_idx" ON "AnalyticsEvent"("sessionId", "createdAt");
CREATE INDEX "AnalyticsEvent_eventName_createdAt_idx" ON "AnalyticsEvent"("eventName", "createdAt");
CREATE INDEX "AnalyticsEvent_screenName_createdAt_idx" ON "AnalyticsEvent"("screenName", "createdAt");
