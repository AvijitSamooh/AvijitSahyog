import {
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { createPublicKey, verify } from 'crypto';

import { FirebaseIdentity } from './auth.types';

interface FirebaseTokenClaims {
  aud?: string;
  email?: string;
  exp?: number;
  iss?: string;
  name?: string;
  picture?: string;
  sub?: string;
}

interface FirebaseCertificateResponse {
  [keyId: string]: string;
}

@Injectable()
export class FirebaseTokenVerifierService {
  private readonly logger = new Logger(FirebaseTokenVerifierService.name);
  private certificateCache?: {
    certificates: FirebaseCertificateResponse;
    expiresAt: number;
  };

  async verify(token: string): Promise<FirebaseIdentity> {
    try {
      const [headerPart, payloadPart, signaturePart] = token.split('.');
      if (!headerPart || !payloadPart || !signaturePart) {
        throw new Error('malformed_token');
      }

      const header = JSON.parse(
        Buffer.from(headerPart, 'base64url').toString('utf8'),
      ) as { alg?: string; kid?: string };

      const claims = JSON.parse(
        Buffer.from(payloadPart, 'base64url').toString('utf8'),
      ) as FirebaseTokenClaims;

      if (header.alg !== 'RS256' || !header.kid) {
        throw new Error('unsupported_token_header');
      }

      const projectId = process.env.FIREBASE_PROJECT_ID;
      if (!projectId) {
        throw new Error('missing_firebase_project_id');
      }

      this.validateClaims(claims, projectId);

      const certificates = await this.getCertificates();
      const certificate = certificates[header.kid];
      if (!certificate) {
        throw new Error('unknown_signing_key');
      }

      const signedData = Buffer.from(
        `${headerPart}.${payloadPart}`,
        'utf8',
      );
      const signature = Buffer.from(signaturePart, 'base64url');
      const publicKey = createPublicKey(certificate);

      const valid = verify('RSA-SHA256', signedData, publicKey, signature);
      if (!valid) {
        throw new Error('invalid_signature');
      }

      if (!claims.sub) {
        throw new Error('missing_subject');
      }

      return {
        uid: claims.sub,
        email: claims.email,
        displayName: claims.name,
        photoUrl: claims.picture,
      };
    } catch (error) {
      const reason = error instanceof Error ? error.message : 'unknown_error';
      this.logger.warn(`Firebase ID token verification failed: ${reason}`);
      throw new UnauthorizedException('Invalid or expired authentication token.');
    }
  }

  private validateClaims(claims: FirebaseTokenClaims, projectId: string): void {
    const now = Math.floor(Date.now() / 1000);

    if (claims.aud !== projectId) {
      throw new Error('invalid_audience');
    }

    if (claims.iss !== `https://securetoken.google.com/${projectId}`) {
      throw new Error('invalid_issuer');
    }

    if (!claims.exp || claims.exp <= now) {
      throw new Error('expired_token');
    }
  }

  private async getCertificates(): Promise<FirebaseCertificateResponse> {
    if (
      this.certificateCache &&
      this.certificateCache.expiresAt > Date.now()
    ) {
      return this.certificateCache.certificates;
    }

    const response = await fetch(
      'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
    );

    if (!response.ok) {
      throw new Error('certificate_fetch_failed');
    }

    const certificates =
      (await response.json()) as FirebaseCertificateResponse;

    const cacheControl = response.headers.get('cache-control');
    const maxAgeMatch = cacheControl?.match(/max-age=(\d+)/);
    const maxAgeSeconds = maxAgeMatch ? Number(maxAgeMatch[1]) : 3600;

    this.certificateCache = {
      certificates,
      expiresAt: Date.now() + maxAgeSeconds * 1000,
    };

    return certificates;
  }
}
