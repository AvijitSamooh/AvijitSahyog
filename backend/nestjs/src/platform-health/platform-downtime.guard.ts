import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { Request } from 'express';
import { FirebaseTokenVerifierService } from '../auth/firebase-token-verifier.service';
import { FirestoreUsersService } from '../users/firestore-users.service';
import { PlatformDowntimeService } from './platform-downtime.service';

@Injectable()
export class PlatformDowntimeGuard implements CanActivate {
  constructor(
    private readonly downtime: PlatformDowntimeService,
    private readonly tokenVerifier: FirebaseTokenVerifierService,
    private readonly users: FirestoreUsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const path = request.path;

    if (
      path === '/health' ||
      path.startsWith('/auth/') ||
      path === '/platform-downtime'
    ) {
      return true;
    }

    const settings = await this.downtime.get();
    if (!settings.enabled || !this.isInsideWindow(settings.startTime, settings.endTime)) {
      return true;
    }

    const token = this.bearerToken(request);
    if (token) {
      try {
        const identity = await this.tokenVerifier.verify(token);
        const user = await this.users.getByFirebaseUid(identity.uid);
        if (user?.role === 'SUPER_ADMIN') return true;
      } catch (_) {
        // Treat an invalid/expired token as a normal non-admin request.
      }
    }

    throw new ServiceUnavailableException({
      statusCode: 503,
      code: 'PLATFORM_DOWNTIME',
      message: settings.message ?? 'The backend is temporarily unavailable.',
      startTime: settings.startTime,
      endTime: settings.endTime,
    });
  }

  private bearerToken(request: Request): string | null {
    const value = request.header('authorization');
    if (!value?.startsWith('Bearer ')) return null;
    return value.slice('Bearer '.length).trim() || null;
  }

  private isInsideWindow(start: string, end: string): boolean {
    const [startHour, startMinute] = start.split(':').map(Number);
    const [endHour, endMinute] = end.split(':').map(Number);
    const startValue = startHour * 60 + startMinute;
    const endValue = endHour * 60 + endMinute;
    const now = new Date();
    const currentValue = now.getHours() * 60 + now.getMinutes();

    if (startValue === endValue) return true;
    if (startValue > endValue) {
      return currentValue >= startValue || currentValue < endValue;
    }
    return currentValue >= startValue && currentValue < endValue;
  }
}
