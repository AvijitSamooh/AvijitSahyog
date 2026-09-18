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
    },
  },
  {
    slug: 'education',
    displayOrder: 2,
    translations: {
      en: {
        name: 'Education',
        description: 'Education-related assistance and recognition opportunities.',
      },
      hi: {
        name: 'शिक्षा',
        description: 'शिक्षा से जुड़ी सहायता और सम्मान के अवसर।',
      },
      mr: {
        name: 'शिक्षण',
        description: 'शिक्षणाशी संबंधित सहाय्य आणि सन्मानाच्या संधी.',
      },
      gu: {
        name: 'શિક્ષણ',
        description: 'શિક્ષણ સંબંધિત સહાય અને સન્માનની તકો.',
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
    causes: ['education-assistance'],
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

  for (const [childSlug, parentSlug] of [
    ['education-assistance', 'education'],
    ['pratibha-samman', 'education'],
  ] as const) {
    await prisma.cause.update({
      where: { slug: childSlug },
      data: { parentId: causeIds.get(parentSlug)! },
    });
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
    {
      name: 'Rahul Kumar',
      cause: 'education-assistance',
      organisation: 'demo-education-support',
      year: 2025,
      amount: '25000',
      order: 1,
      story: 'Educational support helped Rahul continue his studies and move forward with confidence.',
      photoUrl: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=900&q=80',
    },
    {
      name: 'Amit Patel',
      cause: 'education-assistance',
      organisation: 'demo-education-support',
      year: 2025,
      amount: '12000',
      order: 2,
      story: 'Learning support gave Amit an opportunity to continue building skills for a brighter future.',
      photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=900&q=80',
    },
    {
      name: 'Priya Sharma',
      cause: 'healthcare',
      organisation: 'demo-healthcare-support',
      year: 2024,
      amount: '18000',
      order: 3,
      story: 'Timely medical support helped Priya focus on recovery and regain stability.',
      photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=900&q=80',
    },
    {
      name: 'Sanjay Mehta',
      cause: 'healthcare',
      organisation: 'demo-healthcare-support',
      year: 2023,
      amount: '30000',
      order: 4,
      story: 'Medical assistance helped Sanjay access essential treatment during a difficult time.',
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80',
    },
    {
      name: 'Gopal Care Initiative',
      cause: 'jeev-daya',
      organisation: 'demo-animal-welfare',
      year: 2025,
      amount: '15000',
      order: 5,
      story: 'Support contributed to food, care and protection for animals in need.',
      photoUrl: 'https://images.unsplash.com/photo-1558788353-f76d92427f16?auto=format&fit=crop&w=900&q=80',
    },
    {
      name: 'Seva Community Project',
      cause: 'community-support',
      organisation: 'demo-community-support',
      year: 2024,
      amount: '20000',
      order: 6,
      story: 'Community support helped provide practical assistance to families facing hardship.',
      photoUrl: 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=900&q=80',
    },
  ];

  for (const beneficiary of beneficiarySeeds) {
    const organisation = await prisma.organisation.findUnique({
      where: { slug: beneficiary.organisation },
      select: { id: true },
    });
    const matchingSeeds = await prisma.beneficiary.findMany({
      where: {
        name: beneficiary.name,
        causeId: causeIds.get(beneficiary.cause)!,
        organisationId: organisation?.id,
        supportedYear: beneficiary.year,
        contributionAmount: beneficiary.amount,
        photoUrl: beneficiary.photoUrl,
      },
      orderBy: { createdAt: 'asc' },
      select: { id: true },
    });
    const existing = matchingSeeds[0];
    if (matchingSeeds.length > 1) {
      await prisma.beneficiary.deleteMany({
        where: { id: { in: matchingSeeds.slice(1).map((item) => item.id) } },
      });
    }
    const data = {
      name: beneficiary.name,
      photoUrl: beneficiary.photoUrl,
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
