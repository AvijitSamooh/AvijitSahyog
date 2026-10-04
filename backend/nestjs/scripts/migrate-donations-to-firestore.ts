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
    const donations = await prisma.donation.findMany({
      orderBy: { createdAt: 'asc' },
      include: { allocations: true },
    });

    for (let index = 0; index < donations.length; index += BATCH_SIZE) {
      const batch = db.batch();
      for (const donation of donations.slice(index, index + BATCH_SIZE)) {
        batch.set(db.collection('donations').doc(donation.id), {
          id: donation.id,
          amount: donation.amount.toString(),
          currency: donation.currency,
          status: donation.status,
          allocations: donation.allocations.map((allocation) => ({
            id: allocation.id,
            causeId: allocation.causeId,
            organisationId: allocation.organisationId,
            amount: allocation.amount.toString(),
            createdAt: Timestamp.fromDate(allocation.createdAt),
          })),
          createdAt: Timestamp.fromDate(donation.createdAt),
          updatedAt: Timestamp.fromDate(donation.updatedAt),
        }, { merge: true });
      }
      await batch.commit();
    }

    const firestoreCount = (await db.collection('donations').count().get()).data().count;
    console.log(JSON.stringify({
      postgres: { donations: donations.length },
      firestore: { donations: firestoreCount },
      reconciled: donations.length === firestoreCount,
    }, null, 2));

    if (donations.length !== firestoreCount) {
      throw new Error('Donation Firestore migration reconciliation failed.');
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error('Donation Firestore migration failed:', error);
  process.exitCode = 1;
});
