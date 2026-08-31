import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseIdentity } from './auth.types';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  async getCurrentUser(identity: FirebaseIdentity) {
    return this.prisma.user.upsert({
      where: { firebaseUid: identity.uid },
      create: {
        firebaseUid: identity.uid,
        email: identity.email,
        displayName: identity.displayName,
        photoUrl: identity.photoUrl,
      },
      update: {
        email: identity.email,
        displayName: identity.displayName,
        photoUrl: identity.photoUrl,
      },
      select: {
        id: true,
        email: true,
        displayName: true,
        photoUrl: true,
        role: true,
        preferredLanguage: true,
      },
    });
  }
}
