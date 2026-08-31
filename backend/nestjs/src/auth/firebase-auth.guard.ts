import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { FirebaseTokenVerifierService } from './firebase-token-verifier.service';
import { AuthenticatedRequest } from './auth.types';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(private readonly tokenVerifier: FirebaseTokenVerifierService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request & Partial<AuthenticatedRequest>>();
    const authorization = request.headers.authorization;
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authentication is required.');
    }
    const token = authorization.substring('Bearer '.length).trim();
    if (!token) throw new UnauthorizedException('Authentication is required.');
    request.user = await this.tokenVerifier.verify(token);
    return true;
  }
}
