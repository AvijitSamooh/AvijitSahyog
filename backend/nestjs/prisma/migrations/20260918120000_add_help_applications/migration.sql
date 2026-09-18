CREATE TYPE "HelpApplicationType" AS ENUM ('EDUCATION_ASSISTANCE', 'MEDICAL_HELP', 'PRATIBHA_SAMMAN');
CREATE TYPE "HelpApplicationStatus" AS ENUM ('SUBMITTED', 'UNDER_REVIEW', 'CLARIFICATION_REQUIRED', 'APPROVED_FOR_DONATION', 'REJECTED', 'CONSIDERED_FOR_SAMMAN', 'NOT_SELECTED');

CREATE TABLE "HelpApplication" (
  "id" UUID NOT NULL,
  "applicantId" UUID NOT NULL,
  "type" "HelpApplicationType" NOT NULL,
  "status" "HelpApplicationStatus" NOT NULL DEFAULT 'SUBMITTED',
  "requestedAmount" DECIMAL(12,2),
  "approvedAmount" DECIMAL(12,2),
  "rejectionReason" TEXT,
  "clarification" TEXT,
  "adminNote" TEXT,
  "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "reviewedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "HelpApplication_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "HelpApplicationMedia" (
  "id" UUID NOT NULL,
  "applicationId" UUID NOT NULL,
  "mediaId" UUID NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "HelpApplicationMedia_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "HelpApplicationVote" (
  "id" UUID NOT NULL,
  "applicationId" UUID NOT NULL,
  "adminId" UUID NOT NULL,
  "score" INTEGER NOT NULL,
  "comment" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "HelpApplicationVote_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "HelpApplication_applicantId_createdAt_idx" ON "HelpApplication"("applicantId", "createdAt");
CREATE INDEX "HelpApplication_type_status_createdAt_idx" ON "HelpApplication"("type", "status", "createdAt");
CREATE UNIQUE INDEX "HelpApplicationMedia_applicationId_mediaId_key" ON "HelpApplicationMedia"("applicationId", "mediaId");
CREATE INDEX "HelpApplicationMedia_mediaId_idx" ON "HelpApplicationMedia"("mediaId");
CREATE UNIQUE INDEX "HelpApplicationVote_applicationId_adminId_key" ON "HelpApplicationVote"("applicationId", "adminId");
CREATE INDEX "HelpApplicationVote_applicationId_score_idx" ON "HelpApplicationVote"("applicationId", "score");

ALTER TABLE "HelpApplication" ADD CONSTRAINT "HelpApplication_applicantId_fkey" FOREIGN KEY ("applicantId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "HelpApplicationMedia" ADD CONSTRAINT "HelpApplicationMedia_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "HelpApplication"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "HelpApplicationMedia" ADD CONSTRAINT "HelpApplicationMedia_mediaId_fkey" FOREIGN KEY ("mediaId") REFERENCES "Media"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "HelpApplicationVote" ADD CONSTRAINT "HelpApplicationVote_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "HelpApplication"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "HelpApplicationVote" ADD CONSTRAINT "HelpApplicationVote_adminId_fkey" FOREIGN KEY ("adminId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
