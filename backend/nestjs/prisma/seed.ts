import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const languages = [
  { code: 'en', name: 'English', nativeName: 'English', isDefault: true },
  { code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', isDefault: false },
  { code: 'mr', name: 'Marathi', nativeName: 'मराठी', isDefault: false },
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
    },
  },
  {
    slug: 'education',
    displayOrder: 2,
    translations: {
      en: {
        name: 'Education',
        description: 'Support for education and learning opportunities.',
      },
      hi: {
        name: 'शिक्षा',
        description: 'शिक्षा और सीखने के अवसरों के लिए सहयोग।',
      },
      mr: {
        name: 'शिक्षण',
        description: 'शिक्षण आणि शिकण्याच्या संधींसाठी सहकार्य.',
      },
    },
  },
  {
    slug: 'healthcare',
    displayOrder: 3,
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
    },
  },
  {
    slug: 'community-support',
    displayOrder: 4,
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
        name: 'समुदाय सहकार्य',
        description: 'समुदाय कल्याण आणि मदत उपक्रमांसाठी सहकार्य.',
      },
    },
  },
];

const organisations = [
  {
    slug: 'demo-animal-welfare',
    displayOrder: 1,
    translations: {
      en: { name: 'Demo Animal Welfare Organisation', description: 'Seed/demo organisation. Replace with verified organisation details.' },
      hi: { name: 'डेमो पशु सेवा संस्था', description: 'सीड/डेमो संस्था। वास्तविक संस्था की सत्यापित जानकारी से बदलें।' },
      mr: { name: 'डेमो पशु सेवा संस्था', description: 'सीड/डेमो संस्था. सत्यापित संस्थेच्या माहितीसह बदला.' },
    },
    causes: ['jeev-daya'],
  },
  {
    slug: 'demo-education-support',
    displayOrder: 2,
    translations: {
      en: { name: 'Demo Education Support Organisation', description: 'Seed/demo organisation. Replace with verified organisation details.' },
      hi: { name: 'डेमो शिक्षा सहयोग संस्था', description: 'सीड/डेमो संस्था। वास्तविक संस्था की सत्यापित जानकारी से बदलें।' },
      mr: { name: 'डेमो शिक्षण सहकार्य संस्था', description: 'सीड/डेमो संस्था. सत्यापित संस्थेच्या माहितीसह बदला.' },
    },
    causes: ['education'],
  },
  {
    slug: 'demo-healthcare-support',
    displayOrder: 3,
    translations: {
      en: { name: 'Demo Healthcare Support Organisation', description: 'Seed/demo organisation. Replace with verified organisation details.' },
      hi: { name: 'डेमो स्वास्थ्य सेवा संस्था', description: 'सीड/डेमो संस्था। वास्तविक संस्था की सत्यापित जानकारी से बदलें।' },
      mr: { name: 'डेमो आरोग्य सेवा संस्था', description: 'सीड/डेमो संस्था. सत्यापित संस्थेच्या माहितीसह बदला.' },
    },
    causes: ['healthcare'],
  },
  {
    slug: 'demo-community-support',
    displayOrder: 4,
    translations: {
      en: { name: 'Demo Community Support Organisation', description: 'Seed/demo organisation. Replace with verified organisation details.' },
      hi: { name: 'डेमो समुदाय सहयोग संस्था', description: 'सीड/डेमो संस्था। वास्तविक संस्था की सत्यापित जानकारी से बदलें।' },
      mr: { name: 'डेमो समुदाय सहकार्य संस्था', description: 'सीड/डेमो संस्था. सत्यापित संस्थेच्या माहितीसह बदला.' },
    },
    causes: ['community-support'],
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

  for (const organisation of organisations) {
    const record = await prisma.organisation.upsert({
      where: { slug: organisation.slug },
      update: {
        displayOrder: organisation.displayOrder,
        isActive: true,
      },
      create: {
        slug: organisation.slug,
        displayOrder: organisation.displayOrder,
        isActive: true,
      },
    });

    for (const [code, translation] of Object.entries(organisation.translations)) {
      await prisma.organisationTranslation.upsert({
        where: {
          organisationId_languageId: {
            organisationId: record.id,
            languageId: languageIds.get(code)!,
          },
        },
        update: translation,
        create: {
          organisationId: record.id,
          languageId: languageIds.get(code)!,
          ...translation,
        },
      });
    }

    for (const causeSlug of organisation.causes) {
      const causeId = causeIds.get(causeSlug);
      if (!causeId) {
        throw new Error(`Unknown cause slug: ${causeSlug}`);
      }

      await prisma.organisationCause.upsert({
        where: {
          organisationId_causeId: {
            organisationId: record.id,
            causeId,
          },
        },
        update: {
          isActive: true,
        },
        create: {
          organisationId: record.id,
          causeId,
          isActive: true,
        },
      });
    }
  }


  const beneficiarySeeds = [
    { name: 'Rahul Kumar', cause: 'education', organisation: 'demo-education-support', year: 2025, amount: '25000', order: 1, story: 'Educational support helped Rahul continue his studies and move forward with confidence.' },
    { name: 'Priya Sharma', cause: 'healthcare', organisation: 'demo-healthcare-support', year: 2024, amount: '18000', order: 2, story: 'Timely medical support helped Priya focus on recovery and regain stability.' },
    { name: 'Amit Patel', cause: 'education', organisation: 'demo-education-support', year: 2025, amount: '12000', order: 3, story: 'Learning support gave Amit an opportunity to continue building skills for a brighter future.' },
  ];

  for (const beneficiary of beneficiarySeeds) {
    const existing = await prisma.beneficiary.findFirst({
      where: { name: beneficiary.name, causeId: causeIds.get(beneficiary.cause)! },
      select: { id: true },
    });
    const organisation = await prisma.organisation.findUnique({
      where: { slug: beneficiary.organisation },
      select: { id: true },
    });
    const data = {
      name: beneficiary.name,
      story: beneficiary.story,
      supportedYear: beneficiary.year,
      contributionAmount: beneficiary.amount,
      causeId: causeIds.get(beneficiary.cause)!,
      organisationId: organisation?.id,
      isActive: true,
      displayOrder: beneficiary.order,
    };
    if (existing) {
      await prisma.beneficiary.update({ where: { id: existing.id }, data });
    } else {
      await prisma.beneficiary.create({ data });
    }
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
