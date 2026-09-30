CREATE TABLE "ApplicationRule" (
  "id" UUID NOT NULL,
  "type" "HelpApplicationType" NOT NULL,
  "displayOrder" INTEGER NOT NULL DEFAULT 0,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "ApplicationRule_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ApplicationRuleTranslation" (
  "id" UUID NOT NULL,
  "ruleId" UUID NOT NULL,
  "languageId" UUID NOT NULL,
  "text" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "ApplicationRuleTranslation_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "HelpApplicationRuleAcceptance" (
  "id" UUID NOT NULL,
  "applicationId" UUID NOT NULL,
  "ruleId" UUID NOT NULL,
  "ruleText" TEXT NOT NULL,
  "acceptedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "HelpApplicationRuleAcceptance_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ApplicationRuleTranslation_ruleId_languageId_key" ON "ApplicationRuleTranslation"("ruleId","languageId");
CREATE UNIQUE INDEX "HelpApplicationRuleAcceptance_applicationId_ruleId_key" ON "HelpApplicationRuleAcceptance"("applicationId","ruleId");
CREATE INDEX "ApplicationRule_type_isActive_displayOrder_idx" ON "ApplicationRule"("type","isActive","displayOrder");
CREATE INDEX "ApplicationRuleTranslation_languageId_idx" ON "ApplicationRuleTranslation"("languageId");
CREATE INDEX "HelpApplicationRuleAcceptance_applicationId_idx" ON "HelpApplicationRuleAcceptance"("applicationId");

ALTER TABLE "ApplicationRuleTranslation" ADD CONSTRAINT "ApplicationRuleTranslation_ruleId_fkey" FOREIGN KEY ("ruleId") REFERENCES "ApplicationRule"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ApplicationRuleTranslation" ADD CONSTRAINT "ApplicationRuleTranslation_languageId_fkey" FOREIGN KEY ("languageId") REFERENCES "Language"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "HelpApplicationRuleAcceptance" ADD CONSTRAINT "HelpApplicationRuleAcceptance_applicationId_fkey" FOREIGN KEY ("applicationId") REFERENCES "HelpApplication"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "HelpApplicationRuleAcceptance" ADD CONSTRAINT "HelpApplicationRuleAcceptance_ruleId_fkey" FOREIGN KEY ("ruleId") REFERENCES "ApplicationRule"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

INSERT INTO "ApplicationRule" ("id","type","displayOrder","isActive","updatedAt") VALUES
('00000000-0000-0000-0000-000000001001','PRATIBHA_SAMMAN',1,true,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000001002','PRATIBHA_SAMMAN',2,true,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000001003','PRATIBHA_SAMMAN',3,true,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000001004','PRATIBHA_SAMMAN',4,true,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000001005','PRATIBHA_SAMMAN',5,true,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000001006','PRATIBHA_SAMMAN',6,true,CURRENT_TIMESTAMP);

INSERT INTO "ApplicationRuleTranslation" ("id","ruleId","languageId","text","updatedAt")
VALUES
('00000000-0000-0000-0000-000000002001','00000000-0000-0000-0000-000000001001',(SELECT id FROM "Language" WHERE code='en'),'Candidate must be from Pune and the school must also be in Pune.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002002','00000000-0000-0000-0000-000000001001',(SELECT id FROM "Language" WHERE code='hi'),'उम्मीदवार पुणे का होना चाहिए और स्कूल भी पुणे में होना चाहिए।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002003','00000000-0000-0000-0000-000000001001',(SELECT id FROM "Language" WHERE code='mr'),'उमेदवार पुण्यातील असावा आणि शाळाही पुण्यातील असावी.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002004','00000000-0000-0000-0000-000000001001',(SELECT id FROM "Language" WHERE code='gu'),'ઉમેદવાર પુણેનો હોવો જોઈએ અને શાળા પણ પુણેમાં હોવી જોઈએ.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002005','00000000-0000-0000-0000-000000001002',(SELECT id FROM "Language" WHERE code='en'),'Minimum overall marks required are 80% or above.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002006','00000000-0000-0000-0000-000000001002',(SELECT id FROM "Language" WHERE code='hi'),'न्यूनतम कुल अंक 80% या उससे अधिक होने चाहिए।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002007','00000000-0000-0000-0000-000000001002',(SELECT id FROM "Language" WHERE code='mr'),'किमान एकूण गुण 80% किंवा त्याहून अधिक असणे आवश्यक आहे.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002008','00000000-0000-0000-0000-000000001002',(SELECT id FROM "Language" WHERE code='gu'),'લઘુત્તમ કુલ ગુણ 80% અથવા તેનાથી વધુ હોવા જોઈએ.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002009','00000000-0000-0000-0000-000000001003',(SELECT id FROM "Language" WHERE code='en'),'For a grading system, provide the equivalent grade-to-marks mapping with the application.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002010','00000000-0000-0000-0000-000000001003',(SELECT id FROM "Language" WHERE code='hi'),'ग्रेडिंग प्रणाली होने पर ग्रेड और अंकों का समतुल्य मानचित्र आवेदन के साथ देना होगा।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002011','00000000-0000-0000-0000-000000001003',(SELECT id FROM "Language" WHERE code='mr'),'ग्रेडिंग पद्धतीसाठी ग्रेड व गुण यांचे समतुल्य मॅपिंग अर्जासोबत द्यावे.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002012','00000000-0000-0000-0000-000000001003',(SELECT id FROM "Language" WHERE code='gu'),'ગ્રેડિંગ સિસ્ટમ માટે ગ્રેડ અને ગુણનું સમકક્ષ મેપિંગ અરજી સાથે આપવું પડશે.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002013','00000000-0000-0000-0000-000000001004',(SELECT id FROM "Language" WHERE code='en'),'Only the top 50 eligible children will be rewarded.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002014','00000000-0000-0000-0000-000000001004',(SELECT id FROM "Language" WHERE code='hi'),'केवल शीर्ष 50 पात्र बच्चों को सम्मानित किया जाएगा।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002015','00000000-0000-0000-0000-000000001004',(SELECT id FROM "Language" WHERE code='mr'),'फक्त पात्र असलेल्या पहिल्या 50 विद्यार्थ्यांचा गौरव केला जाईल.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002016','00000000-0000-0000-0000-000000001004',(SELECT id FROM "Language" WHERE code='gu'),'માત્ર ટોચના 50 પાત્ર બાળકોને સન્માનિત કરવામાં આવશે.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002017','00000000-0000-0000-0000-000000001005',(SELECT id FROM "Language" WHERE code='en'),'In case of a tie, the candidates individual subject marks will be compared.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002018','00000000-0000-0000-0000-000000001005',(SELECT id FROM "Language" WHERE code='hi'),'टाई होने पर उम्मीदवारों के प्रत्येक विषय के अंकों की तुलना की जाएगी।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002019','00000000-0000-0000-0000-000000001005',(SELECT id FROM "Language" WHERE code='mr'),'समान गुण असल्यास उमेदवारांच्या प्रत्येक विषयातील गुणांची तुलना केली जाईल.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002020','00000000-0000-0000-0000-000000001005',(SELECT id FROM "Language" WHERE code='gu'),'ટાઈની સ્થિતિમાં ઉમેદવારોના દરેક વિષયના ગુણોની સરખામણી કરવામાં આવશે.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002021','00000000-0000-0000-0000-000000001006',(SELECT id FROM "Language" WHERE code='en'),'The candidate must be present at the award ceremony. A relative cannot collect the award on the candidates behalf.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002022','00000000-0000-0000-0000-000000001006',(SELECT id FROM "Language" WHERE code='hi'),'उम्मीदवार का पुरस्कार समारोह में उपस्थित होना आवश्यक है। रिश्तेदार उसकी ओर से पुरस्कार नहीं ले सकता।',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002023','00000000-0000-0000-0000-000000001006',(SELECT id FROM "Language" WHERE code='mr'),'पुरस्कार समारंभाच्या वेळी उमेदवाराची उपस्थिती आवश्यक आहे. उमेदवाराच्या वतीने नातेवाईक पुरस्कार स्वीकारू शकत नाही.',CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000002024','00000000-0000-0000-0000-000000001006',(SELECT id FROM "Language" WHERE code='gu'),'પુરસ્કાર સમારંભમાં ઉમેદવારની હાજરી જરૂરી છે. ઉમેદવારની તરફથી સગા પુરસ્કાર સ્વીકારી શકશે નહીં.',CURRENT_TIMESTAMP);
