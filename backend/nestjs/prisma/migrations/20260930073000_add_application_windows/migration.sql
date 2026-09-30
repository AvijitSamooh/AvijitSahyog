CREATE TABLE "ApplicationWindow" (
    "id" UUID NOT NULL,
    "type" "HelpApplicationType" NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL,
    "closedAt" TIMESTAMP(3),
    "updatedById" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ApplicationWindow_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ApplicationWindow_type_key" ON "ApplicationWindow"("type");
CREATE INDEX "ApplicationWindow_startsAt_closedAt_idx" ON "ApplicationWindow"("startsAt", "closedAt");
