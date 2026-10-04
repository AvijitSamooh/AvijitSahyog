import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Request } from 'express';

import { FirestoreUsersService } from '../users/firestore-users.service';
import { AuthenticatedRequest } from './auth.types';
import { FirebaseAuthGuard } from './firebase-auth.guard';

@Injectable()
export class SuperAdminGuard implements CanActivate {
  constructor(
    private readonly firebaseAuthGuard: FirebaseAuthGuard,
    private readonly users: FirestoreUsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    await this.firebaseAuthGuard.canActivate(context);

    const request = context
      .switchToHttp()
      .getRequest<Request & AuthenticatedRequest>();

    const user = await this.users.getByFirebaseUid(request.user.uid);

    if (user?.role !== 'SUPER_ADMIN') {
      throw new ForbiddenException('Super administrator access is required.');
    }

    return true;
  }
}
