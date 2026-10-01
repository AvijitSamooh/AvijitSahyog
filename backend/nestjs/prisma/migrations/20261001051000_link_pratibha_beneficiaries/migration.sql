-- Link public beneficiaries to the Pratibha Samman application that created them.
ALTER TABLE "Beneficiary"
  ADD COLUMN "sourceApplicationId" UUID;

CREATE UNIQUE INDEX "Beneficiary_sourceApplicationId_key"
  ON "Beneficiary"("sourceApplicationId");

ALTER TABLE "Beneficiary"
  ADD CONSTRAINT "Beneficiary_sourceApplicationId_fkey"
  FOREIGN KEY ("sourceApplicationId") REFERENCES "HelpApplication"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
