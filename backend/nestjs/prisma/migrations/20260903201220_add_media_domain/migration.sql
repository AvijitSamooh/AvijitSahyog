-- CreateEnum
CREATE TYPE "OrganisationMediaPurpose" AS ENUM ('LOGO', 'GALLERY');

-- CreateEnum
CREATE TYPE "BeneficiaryMediaPurpose" AS ENUM ('PROFILE', 'GALLERY');

-- AlterTable
ALTER TABLE "DonationAllocation" ALTER COLUMN "organisationId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "User" ALTER COLUMN "id" DROP DEFAULT;

-- CreateTable
CREATE TABLE "Media" (
    "id" UUID NOT NULL,
    "storageKey" VARCHAR(1000) NOT NULL,
    "mimeType" VARCHAR(100) NOT NULL,
    "fileSize" INTEGER NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Media_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrganisationMedia" (
    "id" UUID NOT NULL,
    "organisationId" UUID NOT NULL,
    "mediaId" UUID NOT NULL,
    "purpose" "OrganisationMediaPurpose" NOT NULL DEFAULT 'GALLERY',
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "isPrimary" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OrganisationMedia_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BeneficiaryMedia" (
    "id" UUID NOT NULL,
    "beneficiaryId" UUID NOT NULL,
    "mediaId" UUID NOT NULL,
    "purpose" "BeneficiaryMediaPurpose" NOT NULL DEFAULT 'GALLERY',
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "isPrimary" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BeneficiaryMedia_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Media_storageKey_key" ON "Media"("storageKey");

-- CreateIndex
CREATE INDEX "OrganisationMedia_organisationId_purpose_displayOrder_idx" ON "OrganisationMedia"("organisationId", "purpose", "displayOrder");

-- CreateIndex
CREATE INDEX "OrganisationMedia_mediaId_idx" ON "OrganisationMedia"("mediaId");

-- CreateIndex
CREATE UNIQUE INDEX "OrganisationMedia_organisationId_mediaId_key" ON "OrganisationMedia"("organisationId", "mediaId");

-- CreateIndex
CREATE INDEX "BeneficiaryMedia_beneficiaryId_purpose_displayOrder_idx" ON "BeneficiaryMedia"("beneficiaryId", "purpose", "displayOrder");

-- CreateIndex
CREATE INDEX "BeneficiaryMedia_mediaId_idx" ON "BeneficiaryMedia"("mediaId");

-- CreateIndex
CREATE UNIQUE INDEX "BeneficiaryMedia_beneficiaryId_mediaId_key" ON "BeneficiaryMedia"("beneficiaryId", "mediaId");

-- AddForeignKey
ALTER TABLE "OrganisationMedia" ADD CONSTRAINT "OrganisationMedia_organisationId_fkey" FOREIGN KEY ("organisationId") REFERENCES "Organisation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganisationMedia" ADD CONSTRAINT "OrganisationMedia_mediaId_fkey" FOREIGN KEY ("mediaId") REFERENCES "Media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BeneficiaryMedia" ADD CONSTRAINT "BeneficiaryMedia_beneficiaryId_fkey" FOREIGN KEY ("beneficiaryId") REFERENCES "Beneficiary"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BeneficiaryMedia" ADD CONSTRAINT "BeneficiaryMedia_mediaId_fkey" FOREIGN KEY ("mediaId") REFERENCES "Media"("id") ON DELETE CASCADE ON UPDATE CASCADE;
