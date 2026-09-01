import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Request } from 'express';

import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedRequest } from './auth.types';
import { FirebaseAuthGuard } from './firebase-auth.guard';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(
    private readonly firebaseAuthGuard: FirebaseAuthGuard,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    await this.firebaseAuthGuard.canActivate(context);

    const request = context
      .switchToHttp()
      .getRequest<Request & AuthenticatedRequest>();

    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: request.user.uid },
      select: { role: true },
    });

    if (user?.role !== 'ADMIN') {
      throw new ForbiddenException('Administrator access is required.');
    }

    return true;
  }
}
