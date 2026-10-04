import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { Timestamp } from 'firebase-admin/firestore';
import { randomUUID } from 'node:crypto';

const USERS_COLLECTION = 'users';
const AUDIT_COLLECTION = 'auditLogs';

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
  const firebaseUid = process.env.SUPER_ADMIN_FIREBASE_UID?.trim();

  if (!firebaseUid) {
    throw new Error('SUPER_ADMIN_FIREBASE_UID is required to bootstrap a Super Admin.');
  }

  const app = getApps()[0] ?? initializeApp(firebaseCredentials());
  const db = (await import('firebase-admin/firestore')).getFirestore(app);
  const snapshot = await db.collection(USERS_COLLECTION)
    .where('firebaseUid', '==', firebaseUid)
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new Error(
      'No Firestore application user exists for SUPER_ADMIN_FIREBASE_UID. Sign in once first or run firestore:migrate-users.',
    );
  }

  const user = snapshot.docs[0];
  const data = user.data();

  if (data.role === 'SUPER_ADMIN') {
    console.log(`Super Admin already configured: ${data.email ?? user.id}`);
    return;
  }

  await db.runTransaction(async (transaction) => {
    const now = Timestamp.now();
    transaction.update(user.ref, { role: 'SUPER_ADMIN', updatedAt: now });

    const auditRef = db.collection(AUDIT_COLLECTION).doc(randomUUID());
    transaction.set(auditRef, {
      id: auditRef.id,
      action: 'USER_ROLE_CHANGED',
      actorUserId: user.id,
      targetUserId: user.id,
      fromRole: data.role,
      toRole: 'SUPER_ADMIN',
      metadata: { reason: 'super_admin_bootstrap' },
      createdAt: now,
    });
  });

  console.log(`Super Admin configured: ${data.email ?? user.id}`);
}

main().catch((error) => {
  console.error('Super Admin bootstrap failed:', error);
  process.exitCode = 1;
});
