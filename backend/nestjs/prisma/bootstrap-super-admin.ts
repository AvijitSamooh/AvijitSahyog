import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const firebaseUid = process.env.SUPER_ADMIN_FIREBASE_UID?.trim();

  if (!firebaseUid) {
    throw new Error(
      'SUPER_ADMIN_FIREBASE_UID is required to bootstrap a Super Admin.',
    );
  }

  const user = await prisma.user.findUnique({
    where: { firebaseUid },
    select: { id: true, email: true, displayName: true, role: true },
  });

  if (!user) {
    throw new Error(
      'No application user exists for SUPER_ADMIN_FIREBASE_UID. Sign in once first so the backend creates the user record.',
    );
  }

  if (user.role === 'SUPER_ADMIN') {
    console.log(`Super Admin already configured: ${user.email ?? user.id}`);
    return;
  }

  await prisma.$transaction(async (tx) => {
    await tx.user.update({
      where: { id: user.id },
      data: { role: 'SUPER_ADMIN' },
    });

    await tx.auditLog.create({
      data: {
        action: 'USER_ROLE_CHANGED',
        actorUserId: user.id,
        targetUserId: user.id,
        fromRole: user.role,
        toRole: 'SUPER_ADMIN',
        metadata: { reason: 'super_admin_bootstrap' },
      },
    });
  });

  console.log(`Super Admin configured: ${user.email ?? user.id}`);
}

main()
  .catch((error) => {
    console.error('Super Admin bootstrap failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
