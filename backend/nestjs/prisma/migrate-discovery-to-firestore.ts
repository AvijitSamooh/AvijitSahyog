import { PrismaClient } from '@prisma/client';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { Timestamp } from 'firebase-admin/firestore';

const BATCH_SIZE = 400;

function firebaseCredentials() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (projectId && clientEmail && privateKey) {
    return { credential: cert({ projectId, clientEmail, privateKey }) };
  }
  return undefined;
}

function timestamp(value: Date) {
  return Timestamp.fromDate(value);
}

function translationsByLanguage(items: Array<{ language: { code: string }; name?: string; description?: string | null }>) {
  return Object.fromEntries(
    items.map((item) => [
      item.language.code,
      {
        name: item.name ?? null,
        description: item.description ?? null,
      },
    ]),
  );
}

async function writeBatches(
  db: FirebaseFirestore.Firestore,
  collection: string,
  documents: Array<{ id: string; data: Record<string, unknown> }>,
) {
  for (let index = 0; index < documents.length; index += BATCH_SIZE) {
    const batch = db.batch();
    for (const document of documents.slice(index, index + BATCH_SIZE)) {
      batch.set(db.collection(collection).doc(document.id), document.data, { merge: true });
    }
    await batch.commit();
  }
}

async function count(db: FirebaseFirestore.Firestore, collection: string) {
  return (await db.collection(collection).count().get()).data().count;
}

async function main() {
  const prisma = new PrismaClient();
  const app = getApps()[0] ?? initializeApp(firebaseCredentials());
  const db = (await import('firebase-admin/firestore')).getFirestore(app);

  try {
    const [languages, causes, organisations, beneficiaries, media] = await Promise.all([
      prisma.language.findMany({ orderBy: { code: 'asc' } }),
      prisma.cause.findMany({
        orderBy: { displayOrder: 'asc' },
        include: {
          translations: { include: { language: true } },
          children: { orderBy: { displayOrder: 'asc' }, select: { id: true } },
          organisations: {
            where: { isActive: true },
            orderBy: { displayOrder: 'asc' },
            select: { organisationId: true, displayOrder: true },
          },
        },
      }),
      prisma.organisation.findMany({
        orderBy: { displayOrder: 'asc' },
        include: {
          translations: { include: { language: true } },
          causes: {
            where: { isActive: true },
            orderBy: { displayOrder: 'asc' },
            select: { causeId: true, displayOrder: true },
          },
          media: {
            orderBy: [{ purpose: 'asc' }, { isPrimary: 'desc' }, { displayOrder: 'asc' }],
            include: { media: true },
          },
        },
      }),
      prisma.beneficiary.findMany({
        orderBy: { displayOrder: 'asc' },
        include: {
          media: {
            orderBy: [{ purpose: 'asc' }, { isPrimary: 'desc' }, { displayOrder: 'asc' }],
            include: { media: true },
          },
        },
      }),
      prisma.media.findMany({ orderBy: { createdAt: 'asc' } }),
    ]);

    await writeBatches(
      db,
      'languages',
      languages.map((language) => ({
        id: language.id,
        data: {
          id: language.id,
          code: language.code,
          name: language.name,
          nativeName: language.nativeName,
          isDefault: language.isDefault,
          isActive: language.isActive,
          createdAt: timestamp(language.createdAt),
          updatedAt: timestamp(language.updatedAt),
        },
      })),
    );

    await writeBatches(
      db,
      'causes',
      causes.map((cause) => ({
        id: cause.id,
        data: {
          id: cause.id,
          slug: cause.slug,
          parentId: cause.parentId,
          isActive: cause.isActive,
          displayOrder: cause.displayOrder,
          translations: translationsByLanguage(cause.translations),
          childIds: cause.children.map((child) => child.id),
          organisationIds: cause.organisations.map((link) => link.organisationId),
          createdAt: timestamp(cause.createdAt),
          updatedAt: timestamp(cause.updatedAt),
        },
      })),
    );

    await writeBatches(
      db,
      'organisations',
      organisations.map((organisation) => ({
        id: organisation.id,
        data: {
          id: organisation.id,
          slug: organisation.slug,
          logoUrl: organisation.logoUrl,
          websiteUrl: organisation.websiteUrl,
          phone: organisation.phone,
          mobileNumber: organisation.mobileNumber,
          email: organisation.email,
          address: organisation.address,
          city: organisation.city,
          state: organisation.state,
          country: organisation.country,
          latitude: organisation.latitude == null ? null : Number(organisation.latitude),
          longitude: organisation.longitude == null ? null : Number(organisation.longitude),
          isActive: organisation.isActive,
          displayOrder: organisation.displayOrder,
          translations: translationsByLanguage(organisation.translations),
          causeIds: organisation.causes.map((link) => link.causeId),
          media: organisation.media.map((link) => ({
            mediaId: link.mediaId,
            purpose: link.purpose,
            displayOrder: link.displayOrder,
            isPrimary: link.isPrimary,
          })),
          createdAt: timestamp(organisation.createdAt),
          updatedAt: timestamp(organisation.updatedAt),
        },
      })),
    );

    await writeBatches(
      db,
      'beneficiaries',
      beneficiaries.map((beneficiary) => ({
        id: beneficiary.id,
        data: {
          id: beneficiary.id,
          sourceApplicationId: beneficiary.sourceApplicationId,
          name: beneficiary.name,
          photoUrl: beneficiary.photoUrl,
          story: beneficiary.story,
          supportedYear: beneficiary.supportedYear,
          contributionAmount: beneficiary.contributionAmount.toString(),
          causeId: beneficiary.causeId,
          organisationId: beneficiary.organisationId,
          isActive: beneficiary.isActive,
          displayOrder: beneficiary.displayOrder,
          media: beneficiary.media.map((link) => ({
            mediaId: link.mediaId,
            purpose: link.purpose,
            displayOrder: link.displayOrder,
            isPrimary: link.isPrimary,
          })),
          createdAt: timestamp(beneficiary.createdAt),
          updatedAt: timestamp(beneficiary.updatedAt),
        },
      })),
    );

    await writeBatches(
      db,
      'media',
      media.map((item) => ({
        id: item.id,
        data: {
          id: item.id,
          uploadedById: item.uploadedById,
          storageKey: item.storageKey,
          mimeType: item.mimeType,
          fileSize: item.fileSize,
          width: item.width,
          height: item.height,
          createdAt: timestamp(item.createdAt),
          updatedAt: timestamp(item.updatedAt),
        },
      })),
    );

    const firestoreCounts = {
      languages: await count(db, 'languages'),
      causes: await count(db, 'causes'),
      organisations: await count(db, 'organisations'),
      beneficiaries: await count(db, 'beneficiaries'),
      media: await count(db, 'media'),
    };

    const postgresCounts = {
      languages: languages.length,
      causes: causes.length,
      organisations: organisations.length,
      beneficiaries: beneficiaries.length,
      media: media.length,
    };

    const reconciled = Object.keys(postgresCounts).every(
      (key) => postgresCounts[key as keyof typeof postgresCounts] === firestoreCounts[key as keyof typeof firestoreCounts],
    );

    console.log(JSON.stringify({ postgres: postgresCounts, firestore: firestoreCounts, reconciled }, null, 2));

    if (!reconciled) {
      throw new Error('Firestore discovery migration reconciliation failed.');
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error('Discovery Firestore migration failed:', error);
  process.exitCode = 1;
});
