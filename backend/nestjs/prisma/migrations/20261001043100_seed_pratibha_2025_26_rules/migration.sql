INSERT INTO "ApplicationRule" ("id","type","displayOrder","isActive","updatedAt") VALUES
('00000000-0000-0000-0000-000000001007','PRATIBHA_SAMMAN',7,true,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000001008','PRATIBHA_SAMMAN',8,true,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000001009','PRATIBHA_SAMMAN',9,true,CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;

INSERT INTO "ApplicationRuleTranslation" ("id","ruleId","languageId","text","updatedAt")
VALUES
('00000000-0000-0000-0000-000000002025','00000000-0000-0000-0000-000000001007',(SELECT id FROM "Language" WHERE code='en'),'This recognition is for the 2025-26 batch only.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002026','00000000-0000-0000-0000-000000001007',(SELECT id FROM "Language" WHERE code='hi'),'यह सम्मान केवल 2025-26 बैच के लिए है।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002027','00000000-0000-0000-0000-000000001007',(SELECT id FROM "Language" WHERE code='mr'),'हा सन्मान फक्त 2025-26 बॅचसाठी आहे.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002028','00000000-0000-0000-0000-000000001007',(SELECT id FROM "Language" WHERE code='gu'),'આ સન્માન માત્ર 2025-26 બેચ માટે છે.',CURRENT_TIMESTAMP),

('00000000-0000-0000-0000-000000002029','00000000-0000-0000-0000-000000001008',(SELECT id FROM "Language" WHERE code='en'),'Applicants must follow the important dates shown for this programme: form availability date, last date for registration and event date.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002030','00000000-0000-0000-0000-000000001008',(SELECT id FROM "Language" WHERE code='hi'),'आवेदकों को इस कार्यक्रम की महत्वपूर्ण तिथियों—फॉर्म उपलब्ध होने की तिथि, पंजीकरण की अंतिम तिथि और कार्यक्रम की तिथि—का पालन करना होगा।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002031','00000000-0000-0000-0000-000000001008',(SELECT id FROM "Language" WHERE code='mr'),'अर्जदारांनी या कार्यक्रमाच्या महत्त्वाच्या तारखा—फॉर्म उपलब्ध होण्याची तारीख, नोंदणीची अंतिम तारीख आणि कार्यक्रमाची तारीख—पाळणे आवश्यक आहे.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002032','00000000-0000-0000-0000-000000001008',(SELECT id FROM "Language" WHERE code='gu'),'અરજદારોએ આ કાર્યક્રમની મહત્વપૂર્ણ તારીખો—ફોર્મ ઉપલબ્ધ થવાની તારીખ, નોંધણીની છેલ્લી તારીખ અને કાર્યક્રમની તારીખ—નું પાલન કરવું જરૂરી છે.',CURRENT_TIMESTAMP),

('00000000-0000-0000-0000-000000002033','00000000-0000-0000-0000-000000001009',(SELECT id FROM "Language" WHERE code='en'),'This event is organised under Avijit Sarv Kalyaan Samiti (Registration No. 01/05/03/37787/21).',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002034','00000000-0000-0000-0000-000000001009',(SELECT id FROM "Language" WHERE code='hi'),'यह कार्यक्रम अविजित सर्व कल्याण समिति (पंजीकरण क्रमांक 01/05/03/37787/21) के अंतर्गत आयोजित किया जाता है।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002035','00000000-0000-0000-0000-000000001009',(SELECT id FROM "Language" WHERE code='mr'),'हा कार्यक्रम अविजित सर्व कल्याण समिती (नोंदणी क्रमांक 01/05/03/37787/21) अंतर्गत आयोजित केला जातो.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002036','00000000-0000-0000-0000-000000001009',(SELECT id FROM "Language" WHERE code='gu'),'આ કાર્યક્રમ અવિજિત સર્વ કલ્યાણ સમિતિ (રજિસ્ટ્રેશન નં. 01/05/03/37787/21) હેઠળ યોજાય છે.',CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;
