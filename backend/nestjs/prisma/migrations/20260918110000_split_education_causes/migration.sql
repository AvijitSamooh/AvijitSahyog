-- Split the existing Education cause into need-based assistance and recognition.
-- Rename the existing cause so existing foreign-key references remain intact.

UPDATE "Cause"
SET slug = 'education-assistance'
WHERE slug = 'education';

INSERT INTO "Cause" (id, slug, "displayOrder", "isActive", "createdAt", "updatedAt")
VALUES ('7b3c1d5e-4f8a-4a7d-9c21-6e5f8b2a3147', 'pratibha-samman', 3, true, NOW(), NOW())
ON CONFLICT (slug) DO UPDATE
SET "displayOrder" = EXCLUDED."displayOrder",
    "isActive" = true,
    "updatedAt" = NOW();

INSERT INTO "CauseTranslation" (id, "causeId", "languageId", name, description, "createdAt", "updatedAt")
SELECT
  md5(c.id::text || l.id::text)::uuid,
  c.id,
  l.id,
  v.name,
  v.description,
  NOW(),
  NOW()
FROM "Cause" c
CROSS JOIN (
  VALUES
    ('en', 'Pratibha Samman', 'Recognize and honour exceptional achievements in education, profession, sports, arts, culture and community service.'),
    ('hi', 'प्रतिभा सम्मान', 'शिक्षा, पेशे, खेल, कला, संस्कृति और समाज सेवा में उत्कृष्ट उपलब्धियों का सम्मान और अभिनंदन।'),
    ('mr', 'प्रतिभा सन्मान', 'शिक्षण, व्यवसाय, क्रीडा, कला, संस्कृती आणि समाजसेवेत उल्लेखनीय कामगिरीचा सन्मान.'),
    ('gu', 'પ્રતિભા સન્માન', 'શિક્ષણ, વ્યવસાય, રમતગમત, કલા, સંસ્કૃતિ અને સમાજસેવામાં ઉત્કૃષ્ટ સિદ્ધિઓનું સન્માન.')
) AS v(code, name, description)
JOIN "Language" l ON l.code = v.code AND l."isActive" = true
WHERE c.slug = 'pratibha-samman'
ON CONFLICT ("causeId", "languageId") DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    "updatedAt" = NOW();

UPDATE "CauseTranslation" ct
SET name = v.name,
    description = v.description,
    "updatedAt" = NOW()
FROM "Cause" c
JOIN "Language" l ON l.id = ct."languageId"
JOIN (
  VALUES
    ('en', 'Education Assistance', 'Need-based support for students who need help continuing their education.'),
    ('hi', 'शिक्षा सहायता', 'शिक्षा जारी रखने के लिए आवश्यकता वाले विद्यार्थियों को सहयोग।'),
    ('mr', 'शिक्षण सहाय्य', 'शिक्षण सुरू ठेवण्यासाठी गरजू विद्यार्थ्यांना सहकार्य.'),
    ('gu', 'શિક્ષણ સહાય', 'શિક્ષણ ચાલુ રાખવા માટે જરૂરિયાતમંદ વિદ્યાર્થીઓને સહાય.')
) AS v(code, name, description) ON v.code = l.code
WHERE c.id = ct."causeId" AND c.slug = 'education-assistance';

INSERT INTO "CauseTranslation" (id, "causeId", "languageId", name, description, "createdAt", "updatedAt")
SELECT md5(c.id::text || l.id::text)::uuid, c.id, l.id, v.name, v.description, NOW(), NOW()
FROM "Cause" c
CROSS JOIN (
  VALUES
    ('en', 'Education Assistance', 'Need-based support for students who need help continuing their education.'),
    ('hi', 'शिक्षा सहायता', 'शिक्षा जारी रखने के लिए आवश्यकता वाले विद्यार्थियों को सहयोग।'),
    ('mr', 'शिक्षण सहाय्य', 'शिक्षण सुरू ठेवण्यासाठी गरजू विद्यार्थ्यांना सहकार्य.'),
    ('gu', 'શિક્ષણ સહાય', 'શિક્ષણ ચાલુ રાખવા માટે જરૂરિયાતમંદ વિદ્યાર્થીઓને સહાય.')
) AS v(code, name, description)
JOIN "Language" l ON l.code = v.code AND l."isActive" = true
WHERE c.slug = 'education-assistance'
  AND NOT EXISTS (
    SELECT 1 FROM "CauseTranslation" existing
    WHERE existing."causeId" = c.id AND existing."languageId" = l.id
  );
