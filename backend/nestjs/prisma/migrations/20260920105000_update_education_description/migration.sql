-- Update the public Education description so the parent cause clearly explains both
-- need-based education assistance and recognition of talented achievers.

UPDATE "CauseTranslation" AS ct
SET "description" = v.description
FROM "Cause" AS c,
     "Language" AS l,
     (
       VALUES
         ('education', 'en', 'We support students from financially underserved backgrounds so they can continue their education, and celebrate talented individuals whose achievements inspire others through Pratibha Samman.'),
         ('education', 'hi', 'हम आर्थिक रूप से जरूरतमंद विद्यार्थियों को शिक्षा जारी रखने में सहयोग देते हैं और अपनी प्रतिभा व उपलब्धियों से प्रेरणा देने वाले विद्यार्थियों का प्रतिभा सम्मान के माध्यम से अभिनंदन करते हैं।'),
         ('education', 'mr', 'आर्थिकदृष्ट्या गरजू विद्यार्थ्यांना शिक्षण सुरू ठेवण्यासाठी सहकार्य करणे आणि आपल्या गुणवत्तेने व उल्लेखनीय कामगिरीने प्रेरणा देणाऱ्या विद्यार्थ्यांचा प्रतिभा सन्मानाद्वारे गौरव करणे.'),
         ('education', 'gu', 'આર્થિક રીતે જરૂરિયાતમંદ વિદ્યાર્થીઓને શિક્ષણ ચાલુ રાખવામાં સહાય કરવી અને પોતાની પ્રતિભા તથા સિદ્ધિઓથી પ્રેરણા આપનાર વિદ્યાર્થીઓનું પ્રતિભા સન્માન દ્વારા સન્માન કરવું.')
     ) AS v(slug, language_code, description)
WHERE ct."causeId" = c."id"
  AND ct."languageId" = l."id"
  AND c."slug" = v.slug
  AND l."code" = v.language_code;
