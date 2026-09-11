-- CreateEnum
CREATE TYPE "AuditAction" AS ENUM ('USER_ROLE_CHANGED');

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "action" "AuditAction" NOT NULL,
    "actorUserId" UUID NOT NULL,
    "targetUserId" UUID,
    "fromRole" "UserRole",
    "toRole" "UserRole",
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AuditLog_action_createdAt_idx" ON "AuditLog"("action", "createdAt");
CREATE INDEX "AuditLog_actorUserId_createdAt_idx" ON "AuditLog"("actorUserId", "createdAt");
CREATE INDEX "AuditLog_targetUserId_createdAt_idx" ON "AuditLog"("targetUserId", "createdAt");

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_actorUserId_fkey" FOREIGN KEY ("actorUserId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_targetUserId_fkey" FOREIGN KEY ("targetUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
