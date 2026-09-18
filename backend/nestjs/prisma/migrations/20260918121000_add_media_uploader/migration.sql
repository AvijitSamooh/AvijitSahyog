ALTER TABLE "Media" ADD COLUMN "uploadedById" UUID;
CREATE INDEX "Media_uploadedById_idx" ON "Media"("uploadedById");
ALTER TABLE "Media" ADD CONSTRAINT "Media_uploadedById_fkey" FOREIGN KEY ("uploadedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
