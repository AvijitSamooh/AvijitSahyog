ALTER TABLE "AnalyticsEvent"
  ADD COLUMN "city" VARCHAR(100),
  ADD COLUMN "language" VARCHAR(10),
  ADD COLUMN "deviceType" VARCHAR(32);

CREATE INDEX "AnalyticsEvent_city_createdAt_idx" ON "AnalyticsEvent"("city", "createdAt");
CREATE INDEX "AnalyticsEvent_language_createdAt_idx" ON "AnalyticsEvent"("language", "createdAt");
CREATE INDEX "AnalyticsEvent_deviceType_createdAt_idx" ON "AnalyticsEvent"("deviceType", "createdAt");
