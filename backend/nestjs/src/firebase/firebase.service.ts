import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { cert, getApps, initializeApp, App } from 'firebase-admin/app';
import { getFirestore, Firestore } from 'firebase-admin/firestore';

@Injectable()
export class FirebaseService implements OnModuleDestroy {
  private readonly app: App;
  readonly db: Firestore;

  constructor() {
    const existing = getApps()[0];
    this.app = existing ?? initializeApp(this.credentials());
    this.db = getFirestore(this.app);
  }

  private credentials() {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (projectId && clientEmail && privateKey) {
      return cert({ projectId, clientEmail, privateKey });
    }

    return undefined;
  }

  async onModuleDestroy() {
    await this.app.delete();
  }
}
