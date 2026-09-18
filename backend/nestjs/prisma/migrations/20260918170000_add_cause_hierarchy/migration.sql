-- Add optional parent/child relationships between causes.
ALTER TABLE "Cause"
  ADD COLUMN "parentId" UUID;

ALTER TABLE "Cause"
  ADD CONSTRAINT "Cause_parentId_fkey"
  FOREIGN KEY ("parentId") REFERENCES "Cause"("id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE INDEX "Cause_parentId_isActive_displayOrder_idx"
  ON "Cause"("parentId", "isActive", "displayOrder");

-- Create the Education parent while keeping existing Education Assistance
-- and Pratibha Samman records intact.
INSERT INTO "Cause" ("id", "slug", "isActive", "displayOrder", "createdAt", "updatedAt")
VALUES (
  '00000000-0000-0000-0000-000000000002',
  'education',
  true,
  2,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
)
ON CONFLICT ("slug") DO NOTHING;

INSERT INTO "CauseTranslation" ("id", "causeId", "languageId", "name", "description")
SELECT
  md5('education-parent-' || l.id::text)::uuid,
  c.id,
  l.id,
  v.name,
  v.description
FROM "Cause" c
CROSS JOIN "Language" l
JOIN (
  VALUES
    ('en', 'Education', 'Education-related assistance and recognition opportunities.'),
    ('hi', 'शिक्षा', 'शिक्षा से जुड़ी सहायता और सम्मान के अवसर।'),
    ('mr', 'शिक्षण', 'शिक्षणाशी संबंधित सहाय्य आणि सन्मानाच्या संधी.'),
    ('gu', 'શિક્ષણ', 'શિક્ષણ સંબંધિત સહાય અને સન્માનની તકો.')
) AS v(code, name, description) ON v.code = l.code
WHERE c.slug = 'education'
ON CONFLICT ("causeId", "languageId") DO UPDATE
SET "name" = EXCLUDED."name",
    "description" = EXCLUDED."description";

UPDATE "Cause"
SET "parentId" = (SELECT id FROM "Cause" WHERE slug = 'education')
WHERE slug IN ('education-assistance', 'pratibha-samman');
