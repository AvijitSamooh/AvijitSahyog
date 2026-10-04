import { PrismaClient } from '@prisma/client';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

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

async function main() {
  const prisma = new PrismaClient();
  const app = getApps()[0] ?? initializeApp(firebaseCredentials());
  const db = getFirestore(app);

  try {
    const [rules, windows] = await Promise.all([
      prisma.applicationRule.findMany({
        include: { translations: { include: { language: true } } },
        orderBy: [{ type: 'asc' }, { displayOrder: 'asc' }],
      }),
      prisma.applicationWindow.findMany({ orderBy: { type: 'asc' } }),
    ]);

    for (let index = 0; index < rules.length; index += BATCH_SIZE) {
      const batch = db.batch();
      for (const rule of rules.slice(index, index + BATCH_SIZE)) {
        batch.set(db.collection('applicationRules').doc(rule.id), {
          id: rule.id,
          type: rule.type,
          displayOrder: rule.displayOrder,
          isActive: rule.isActive,
          translations: Object.fromEntries(
            rule.translations.map((item) => [item.language.code, item.text]),
          ),
          createdAt: Timestamp.fromDate(rule.createdAt),
          updatedAt: Timestamp.fromDate(rule.updatedAt),
        }, { merge: true });
      }
      await batch.commit();
    }

    for (let index = 0; index < windows.length; index += BATCH_SIZE) {
      const batch = db.batch();
      for (const window of windows.slice(index, index + BATCH_SIZE)) {
        batch.set(db.collection('applicationWindows').doc(window.type), {
          type: window.type,
          startsAt: Timestamp.fromDate(window.startsAt),
          registrationEndsAt: window.registrationEndsAt ? Timestamp.fromDate(window.registrationEndsAt) : null,
          eventAt: window.eventAt ? Timestamp.fromDate(window.eventAt) : null,
          closedAt: window.closedAt ? Timestamp.fromDate(window.closedAt) : null,
          updatedById: window.updatedById,
          updatedAt: Timestamp.fromDate(window.updatedAt),
        }, { merge: true });
      }
      await batch.commit();
    }

    const [ruleCount, windowCount] = await Promise.all([
      db.collection('applicationRules').count().get(),
      db.collection('applicationWindows').count().get(),
    ]);

    const firestore = {
      applicationRules: ruleCount.data().count,
      applicationWindows: windowCount.data().count,
    };
    const postgres = {
      applicationRules: rules.length,
      applicationWindows: windows.length,
    };

    const reconciled =
      postgres.applicationRules === firestore.applicationRules &&
      postgres.applicationWindows === firestore.applicationWindows;

    console.log(JSON.stringify({ postgres, firestore, reconciled }, null, 2));
    if (!reconciled) throw new Error('Application configuration migration reconciliation failed.');
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error('Application configuration Firestore migration failed:', error);
  process.exitCode = 1;
});
