CREATE TABLE "PlatformHealthEvent" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "type" VARCHAR(32) NOT NULL,
  "statusCode" INTEGER,
  "route" VARCHAR(200),
  "method" VARCHAR(16),
  "message" VARCHAR(500),
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PlatformHealthEvent_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "PlatformHealthEvent_createdAt_idx" ON "PlatformHealthEvent"("createdAt");
CREATE INDEX "PlatformHealthEvent_type_createdAt_idx" ON "PlatformHealthEvent"("type", "createdAt");
CREATE INDEX "PlatformHealthEvent_statusCode_createdAt_idx" ON "PlatformHealthEvent"("statusCode", "createdAt");
