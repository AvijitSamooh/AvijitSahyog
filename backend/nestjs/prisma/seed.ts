import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const languages = [
  { code: 'en', name: 'English', nativeName: 'English', isDefault: true },
  { code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', isDefault: false },
  { code: 'mr', name: 'Marathi', nativeName: 'मराठी', isDefault: false },
  { code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', isDefault: false },
];

const causes = [
  {
    slug: 'jeev-daya',
    displayOrder: 1,
    translations: {
      en: {
        name: 'Jeev Daya',
        description: 'Support for animal welfare, care and protection.',
      },
      hi: {
        name: 'जीव दया',
        description: 'जीवों की सेवा, देखभाल और संरक्षण के लिए सहयोग।',
      },
      mr: {
        name: 'जीव दया',
        description: 'जीवांची सेवा, काळजी आणि संरक्षणासाठी सहकार्य.',
      },
      gu: {
        name: 'જીવ દયા',
        description: 'પ્રાણીઓની સેવા, સંભાળ અને સંરક્ષણ માટે સહાય.',
      },
    },
  },
  {
    slug: 'education',
    displayOrder: 2,
    translations: {
      en: {
        name: 'Education',
        description: 'We support students from financially underserved backgrounds so they can continue their education, and celebrate talented individuals whose achievements inspire others through Pratibha Samman.',
      },
      hi: {
        name: 'शिक्षा',
        description: 'हम आर्थिक रूप से जरूरतमंद विद्यार्थियों को शिक्षा जारी रखने में सहयोग देते हैं और अपनी प्रतिभा व उपलब्धियों से प्रेरणा देने वाले विद्यार्थियों का प्रतिभा सम्मान के माध्यम से अभिनंदन करते हैं।',
      },
      mr: {
        name: 'शिक्षण',
        description: 'आर्थिकदृष्ट्या गरजू विद्यार्थ्यांना शिक्षण सुरू ठेवण्यासाठी सहकार्य करणे आणि आपल्या गुणवत्तेने व उल्लेखनीय कामगिरीने प्रेरणा देणाऱ्या विद्यार्थ्यांचा प्रतिभा सन्मानाद्वारे गौरव करणे.',
      },
      gu: {
        name: 'શિક્ષણ',
        description: 'આર્થિક રીતે જરૂરિયાતમંદ વિદ્યાર્થીઓને શિક્ષણ ચાલુ રાખવામાં સહાય કરવી અને પોતાની પ્રતિભા તથા સિદ્ધિઓથી પ્રેરણા આપનાર વિદ્યાર્થીઓનું પ્રતિભા સન્માન દ્વારા સન્માન કરવું.',
      },
    },
  },
  {
    slug: 'education-assistance',
    displayOrder: 1,
    translations: {
      en: {
        name: 'Education Assistance',
        description: 'Need-based support for students who need help continuing their education.',
      },
      hi: {
        name: 'शिक्षा सहायता',
        description: 'शिक्षा जारी रखने के लिए आवश्यकता वाले विद्यार्थियों को सहयोग।',
      },
      mr: {
        name: 'शिक्षण सहाय्य',
        description: 'शिक्षण सुरू ठेवण्यासाठी गरजू विद्यार्थ्यांना सहकार्य.',
      },
      gu: {
        name: 'શિક્ષણ સહાય',
        description: 'શિક્ષણ ચાલુ રાખવા માટે જરૂરિયાતમંદ વિદ્યાર્થીઓને સહાય.',
      },
    },
  },
  {
    slug: 'pratibha-samman',
    displayOrder: 2,
    translations: {
      en: {
        name: 'Pratibha Samman',
        description: 'Recognize and honour exceptional achievements in education, profession, sports, arts, culture and community service.',
      },
      hi: {
        name: 'प्रतिभा सम्मान',
        description: 'शिक्षा, पेशे, खेल, कला, संस्कृति और समाज सेवा में उत्कृष्ट उपलब्धियों का सम्मान और अभिनंदन।',
      },
      mr: {
        name: 'प्रतिभा सन्मान',
        description: 'शिक्षण, व्यवसाय, क्रीडा, कला, संस्कृती आणि समाजसेवेत उल्लेखनीय कामगिरीचा सन्मान.',
      },
      gu: {
        name: 'પ્રતિભા સન્માન',
        description: 'શિક્ષણ, વ્યવસાય, રમતગમત, કલા, સંસ્કૃતિ અને સમાજસેવામાં ઉત્કૃષ્ટ સિદ્ધિઓનું સન્માન.',
      },
    },
  },
  {
    slug: 'healthcare',
    displayOrder: 4,
    translations: {
      en: {
        name: 'Healthcare',
        description: 'Support for healthcare and medical assistance.',
      },
      hi: {
        name: 'स्वास्थ्य सेवा',
        description: 'स्वास्थ्य और चिकित्सा सहायता के लिए सहयोग।',
      },
      mr: {
        name: 'आरोग्य सेवा',
        description: 'आरोग्य आणि वैद्यकीय मदतीसाठी सहकार्य.',
      },
      gu: {
        name: 'આરોગ્ય સેવા',
        description: 'આરોગ્ય અને તબીબી સહાય માટે સહયોગ.',
      },
    },
  },
  {
    slug: 'community-support',
    displayOrder: 5,
    translations: {
      en: {
        name: 'Community Support',
        description: 'Support for community welfare and relief initiatives.',
      },
      hi: {
        name: 'समुदाय सहयोग',
        description: 'समुदाय कल्याण और राहत पहलों के लिए सहयोग।',
      },
      mr: {
        name: 'समुदાય સહकार्य',
        description: 'સમુદાય કલ્યાણ અને રાહત પહેલ માટે સહયોગ.',
      },
    },
  },
];


async function main() {
  const languageIds = new Map<string, string>();

  for (const language of languages) {
    const record = await prisma.language.upsert({
      where: { code: language.code },
      update: {
        name: language.name,
        nativeName: language.nativeName,
        isDefault: language.isDefault,
        isActive: true,
      },
      create: {
        code: language.code,
        name: language.name,
        nativeName: language.nativeName,
        isDefault: language.isDefault,
        isActive: true,
      },
    });

    languageIds.set(language.code, record.id);
  }

  const causeIds = new Map<string, string>();

  for (const cause of causes) {
    const record = await prisma.cause.upsert({
      where: { slug: cause.slug },
      update: {
        displayOrder: cause.displayOrder,
        isActive: true,
      },
      create: {
        slug: cause.slug,
        displayOrder: cause.displayOrder,
        isActive: true,
      },
    });

    causeIds.set(cause.slug, record.id);

    for (const [code, translation] of Object.entries(cause.translations)) {
      await prisma.causeTranslation.upsert({
        where: {
          causeId_languageId: {
            causeId: record.id,
            languageId: languageIds.get(code)!,
          },
        },
        update: translation,
        create: {
          causeId: record.id,
          languageId: languageIds.get(code)!,
          ...translation,
        },
      });
    }
  }

  for (const [childSlug, parentSlug] of [
    ['education-assistance', 'education'],
    ['pratibha-samman', 'education'],
  ] as const) {
    await prisma.cause.update({
      where: { slug: childSlug },
      data: { parentId: causeIds.get(parentSlug)! },
    });
  }



  console.log('Database seed completed successfully.');
}

main()
  .catch((error) => {
    console.error('Database seed failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
