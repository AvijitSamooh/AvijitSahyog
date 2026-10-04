import { Injectable } from '@nestjs/common';
import { FirestoreUsersService } from '../users/firestore-users.service';
import { FirebaseIdentity } from './auth.types';

@Injectable()
export class AuthService {
  constructor(private readonly users: FirestoreUsersService) {}

  async getCurrentUser(identity: FirebaseIdentity) {
    const user = await this.users.upsertFromIdentity(identity);

    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      role: user.role,
      preferredLanguage: user.preferredLanguage,
    };
  }
}
