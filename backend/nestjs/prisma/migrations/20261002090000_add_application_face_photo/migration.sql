-- Add a dedicated face photo to every new application.
ALTER TABLE "HelpApplication" ADD COLUMN "facePhotoMediaId" UUID;

CREATE INDEX "HelpApplication_facePhotoMediaId_idx" ON "HelpApplication"("facePhotoMediaId");

ALTER TABLE "HelpApplication"
  ADD CONSTRAINT "HelpApplication_facePhotoMediaId_fkey"
  FOREIGN KEY ("facePhotoMediaId") REFERENCES "Media"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
