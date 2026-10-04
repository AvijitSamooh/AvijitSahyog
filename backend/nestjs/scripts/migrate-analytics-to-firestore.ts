import { PrismaClient } from '@prisma/client';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

const BATCH_SIZE = 400;

function firebaseCredentials() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  if (projectId && clientEmail && privateKey) return { credential: cert({ projectId, clientEmail, privateKey }) };
  return undefined;
}

async function main() {
  const prisma = new PrismaClient();
  const app = getApps()[0] ?? initializeApp(firebaseCredentials());
  const db = getFirestore(app);
  try {
    const events = await prisma.analyticsEvent.findMany({ orderBy: { createdAt: 'asc' } });

    for (let index = 0; index < events.length; index += BATCH_SIZE) {
      const batch = db.batch();
      for (const event of events.slice(index, index + BATCH_SIZE)) {
        batch.set(db.collection('analyticsEvents').doc(event.id), {
          id: event.id,
          clientId: event.clientId,
          sessionId: event.sessionId,
          eventName: event.eventName,
          screenName: event.screenName,
          interactionType: event.interactionType,
          target: event.target,
          city: event.city,
          language: event.language,
          deviceType: event.deviceType,
          createdAt: Timestamp.fromDate(event.createdAt),
        }, { merge: true });
      }
      await batch.commit();
    }

    const firestoreCount = (await db.collection('analyticsEvents').count().get()).data().count;
    console.log(JSON.stringify({
      postgres: { analyticsEvents: events.length },
      firestore: { analyticsEvents: firestoreCount },
      reconciled: events.length === firestoreCount,
    }, null, 2));

    if (events.length !== firestoreCount) {
      throw new Error('Analytics Firestore migration reconciliation failed.');
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error('Analytics Firestore migration failed:', error);
  process.exitCode = 1;
});
