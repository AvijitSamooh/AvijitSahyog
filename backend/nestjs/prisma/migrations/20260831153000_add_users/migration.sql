CREATE TYPE "UserRole" AS ENUM ('USER', 'ADMIN');

CREATE TABLE "User" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "firebaseUid" VARCHAR(128) NOT NULL,
    "email" VARCHAR(320),
    "displayName" VARCHAR(250),
    "photoUrl" VARCHAR(1000),
    "role" "UserRole" NOT NULL DEFAULT 'USER',
    "preferredLanguage" VARCHAR(10),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "User_firebaseUid_key" ON "User"("firebaseUid");
CREATE INDEX "User_role_idx" ON "User"("role");
