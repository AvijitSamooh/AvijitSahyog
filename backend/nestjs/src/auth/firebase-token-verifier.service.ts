import { Injectable, UnauthorizedException } from '@nestjs/common';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

import { FirebaseIdentity } from './auth.types';

@Injectable()
export class FirebaseTokenVerifierService {
  async verify(token: string): Promise<FirebaseIdentity> {
    try {
      if (getApps().length === 0) {
        initializeApp({ credential: applicationDefault() });
      }

      const decoded = await getAuth().verifyIdToken(token);
      return {
        uid: decoded.uid,
        email: decoded.email,
        displayName: decoded.name,
        photoUrl: decoded.picture,
      };
    } catch {
      throw new UnauthorizedException('Invalid or expired authentication token.');
    }
  }
}
