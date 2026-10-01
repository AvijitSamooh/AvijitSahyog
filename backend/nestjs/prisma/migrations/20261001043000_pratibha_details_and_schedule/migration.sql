ALTER TABLE "HelpApplication"
  ADD COLUMN "motherName" VARCHAR(250),
  ADD COLUMN "fatherName" VARCHAR(250),
  ADD COLUMN "dateOfBirth" TIMESTAMP(3),
  ADD COLUMN "classStandard" VARCHAR(100),
  ADD COLUMN "schoolInstituteName" VARCHAR(300),
  ADD COLUMN "accomplishments" TEXT,
  ADD COLUMN "certificatePhotoMediaId" UUID;

ALTER TABLE "ApplicationWindow"
  ADD COLUMN "registrationEndsAt" TIMESTAMP(3),
  ADD COLUMN "eventAt" TIMESTAMP(3);

CREATE INDEX "HelpApplication_certificatePhotoMediaId_idx"
  ON "HelpApplication"("certificatePhotoMediaId");

CREATE INDEX "ApplicationWindow_registrationEndsAt_eventAt_idx"
  ON "ApplicationWindow"("registrationEndsAt","eventAt");

ALTER TABLE "HelpApplication"
  ADD CONSTRAINT "HelpApplication_certificatePhotoMediaId_fkey"
  FOREIGN KEY ("certificatePhotoMediaId") REFERENCES "Media"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
