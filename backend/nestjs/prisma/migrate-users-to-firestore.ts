import { PrismaClient } from '@prisma/client';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const USERS_COLLECTION = 'users';
const AUDIT_COLLECTION = 'auditLogs';
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

function searchTokensFor(values: Array<string | null | undefined>): string[] {
  const tokens = new Set<string>();
  for (const value of values) {
    const normalized = value?.trim().toLowerCase();
    if (!normalized) continue;
    for (const word of normalized.split(/[^\p{L}\p{N}]+/u).filter(Boolean)) {
      const max = Math.min(word.length, 32);
      for (let length = 1; length <= max; length += 1) tokens.add(word.slice(0, length));
    }
  }
  return [...tokens];
}

async function main() {
  const prisma = new PrismaClient();
  const app = getApps()[0] ?? initializeApp(firebaseCredentials());
  const db = getFirestore(app);

  try {
    const users = await prisma.user.findMany({ orderBy: { createdAt: 'asc' } });
    const audits = await prisma.auditLog.findMany({ orderBy: { createdAt: 'asc' } });

    let migratedUsers = 0;
    for (let index = 0; index < users.length; index += BATCH_SIZE) {
      const batch = db.batch();
      for (const user of users.slice(index, index + BATCH_SIZE)) {
        const ref = db.collection(USERS_COLLECTION).doc(user.id);
        batch.set(ref, {
          id: user.id,
          firebaseUid: user.firebaseUid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          role: user.role,
          preferredLanguage: user.preferredLanguage,
          createdAt: Timestamp.fromDate(user.createdAt),
          updatedAt: Timestamp.fromDate(user.updatedAt),
          searchTokens: searchTokensFor([user.displayName, user.email]),
        }, { merge: true });
        migratedUsers += 1;
      }
      await batch.commit();
    }

    let migratedAudits = 0;
    for (let index = 0; index < audits.length; index += BATCH_SIZE) {
      const batch = db.batch();
      for (const audit of audits.slice(index, index + BATCH_SIZE)) {
        const ref = db.collection(AUDIT_COLLECTION).doc(audit.id);
        batch.set(ref, {
          id: audit.id,
          action: audit.action,
          actorUserId: audit.actorUserId,
          targetUserId: audit.targetUserId,
          fromRole: audit.fromRole,
          toRole: audit.toRole,
          metadata: audit.metadata ?? null,
          createdAt: Timestamp.fromDate(audit.createdAt),
        }, { merge: true });
        migratedAudits += 1;
      }
      await batch.commit();
    }

    const firestoreUserCount = (await db.collection(USERS_COLLECTION).count().get()).data().count;
    const firestoreAuditCount = (await db.collection(AUDIT_COLLECTION).count().get()).data().count;

    console.log(JSON.stringify({
      postgres: { users: users.length, auditLogs: audits.length },
      firestore: { users: firestoreUserCount, auditLogs: firestoreAuditCount },
      migratedUsers,
      migratedAudits,
      reconciled: users.length === firestoreUserCount && audits.length === firestoreAuditCount,
    }, null, 2));

    if (users.length !== firestoreUserCount || audits.length !== firestoreAuditCount) {
      throw new Error('Firestore user migration reconciliation failed.');
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error('User Firestore migration failed:', error);
  process.exitCode = 1;
});
