-- CreateTable
CREATE TABLE "Beneficiary" (
    "id" UUID NOT NULL,
    "name" VARCHAR(250) NOT NULL,
    "photoUrl" VARCHAR(1000),
    "story" TEXT,
    "supportedYear" INTEGER NOT NULL,
    "contributionAmount" DECIMAL(12,2) NOT NULL,
    "causeId" UUID NOT NULL,
    "organisationId" UUID,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Beneficiary_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Beneficiary_causeId_isActive_displayOrder_idx"
ON "Beneficiary"("causeId", "isActive", "displayOrder");

-- CreateIndex
CREATE INDEX "Beneficiary_supportedYear_isActive_idx"
ON "Beneficiary"("supportedYear", "isActive");

-- CreateIndex
CREATE INDEX "Beneficiary_name_idx"
ON "Beneficiary"("name");

-- AddForeignKey
ALTER TABLE "Beneficiary"
ADD CONSTRAINT "Beneficiary_causeId_fkey"
FOREIGN KEY ("causeId") REFERENCES "Cause"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Beneficiary"
ADD CONSTRAINT "Beneficiary_organisationId_fkey"
FOREIGN KEY ("organisationId") REFERENCES "Organisation"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
