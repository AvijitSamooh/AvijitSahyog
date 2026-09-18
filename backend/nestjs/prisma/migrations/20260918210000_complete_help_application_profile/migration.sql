ALTER TABLE "HelpApplication"
  ADD COLUMN "applicantName" VARCHAR(250),
  ADD COLUMN "mobileNumber" VARCHAR(20),
  ADD COLUMN "email" VARCHAR(320),
  ADD COLUMN "address" TEXT,
  ADD COLUMN "city" VARCHAR(100),
  ADD COLUMN "state" VARCHAR(100),
  ADD COLUMN "pincode" VARCHAR(10);

-- Existing rows predate applicant details. Preserve them with values from
-- the linked user where possible; new applications require the full form.
UPDATE "HelpApplication" h
SET
  "applicantName" = COALESCE(NULLIF(u."displayName", ''), 'Existing applicant'),
  "email" = u."email",
  "mobileNumber" = '0000000000',
  "address" = 'Not provided',
  "city" = 'Not provided',
  "state" = 'Not provided',
  "pincode" = '000000'
FROM "User" u
WHERE u.id = h."applicantId"
  AND "applicantName" IS NULL;

ALTER TABLE "HelpApplication"
  ALTER COLUMN "applicantName" SET NOT NULL,
  ALTER COLUMN "mobileNumber" SET NOT NULL,
  ALTER COLUMN "address" SET NOT NULL,
  ALTER COLUMN "city" SET NOT NULL,
  ALTER COLUMN "state" SET NOT NULL,
  ALTER COLUMN "pincode" SET NOT NULL;
