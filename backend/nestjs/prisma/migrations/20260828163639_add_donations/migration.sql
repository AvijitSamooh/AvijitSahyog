-- CreateEnum
CREATE TYPE "DonationStatus" AS ENUM ('PENDING', 'PAYMENT_PENDING', 'PAID', 'FAILED', 'CANCELLED');

-- CreateTable
CREATE TABLE "Donation" (
    "id" UUID NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "currency" VARCHAR(3) NOT NULL DEFAULT 'INR',
    "status" "DonationStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Donation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DonationAllocation" (
    "id" UUID NOT NULL,
    "donationId" UUID NOT NULL,
    "causeId" UUID NOT NULL,
    "organisationId" UUID NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DonationAllocation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Donation_status_createdAt_idx" ON "Donation"("status", "createdAt");

-- CreateIndex
CREATE INDEX "DonationAllocation_donationId_idx" ON "DonationAllocation"("donationId");

-- CreateIndex
CREATE INDEX "DonationAllocation_causeId_idx" ON "DonationAllocation"("causeId");

-- CreateIndex
CREATE INDEX "DonationAllocation_organisationId_idx" ON "DonationAllocation"("organisationId");

-- AddForeignKey
ALTER TABLE "DonationAllocation" ADD CONSTRAINT "DonationAllocation_donationId_fkey" FOREIGN KEY ("donationId") REFERENCES "Donation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DonationAllocation" ADD CONSTRAINT "DonationAllocation_causeId_fkey" FOREIGN KEY ("causeId") REFERENCES "Cause"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DonationAllocation" ADD CONSTRAINT "DonationAllocation_organisationId_fkey" FOREIGN KEY ("organisationId") REFERENCES "Organisation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
