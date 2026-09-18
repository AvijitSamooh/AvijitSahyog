ALTER TABLE "HelpApplication"
  ADD COLUMN "applicantName" VARCHAR(250),
  ADD COLUMN "mobileNumber" VARCHAR(20),
  ADD COLUMN "email" VARCHAR(320),
  ADD COLUMN "address" TEXT,
  ADD COLUMN "city" VARCHAR(100),
  ADD COLUMN "state" VARCHAR(100),
  ADD COLUMN "pincode" VARCHAR(10);

-- Preserve useful identity data for applications that existed before these fields.
UPDATE "HelpApplication" h
SET
  "applicantName" = COALESCE(h."applicantName", u."displayName"),
  "email" = COALESCE(h."email", u."email")
FROM "User" u
WHERE h."applicantId" = u."id";
