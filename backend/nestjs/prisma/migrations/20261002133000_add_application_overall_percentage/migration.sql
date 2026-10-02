ALTER TABLE "HelpApplication" ADD COLUMN "overallPercentage" DECIMAL(5,2);

CREATE INDEX "HelpApplication_type_overallPercentage_idx" ON "HelpApplication"("type", "overallPercentage");