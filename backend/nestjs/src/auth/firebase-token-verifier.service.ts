import { Injectable, UnauthorizedException } from '@nestjs/common';

import { FirebaseIdentity } from './auth.types';

interface GoogleTokenInfo {
  user_id?: string;
  email?: string;
  name?: string;
  picture?: string;
}

@Injectable()
export class FirebaseTokenVerifierService {
  async verify(token: string): Promise<FirebaseIdentity> {
    try {
      const response = await fetch(
        'https://oauth2.googleapis.com/tokeninfo?id_token=' +
            encodeURIComponent(token),
      );

      if (!response.ok) {
        throw new Error('Token verification failed');
      }

      const decoded = (await response.json()) as GoogleTokenInfo;
      if (!decoded.user_id) {
        throw new Error('Verified token has no user id');
      }

      return {
        uid: decoded.user_id,
        email: decoded.email,
        displayName: decoded.name,
        photoUrl: decoded.picture,
      };
    } catch {
      throw new UnauthorizedException('Invalid or expired authentication token.');
    }
  }
}
