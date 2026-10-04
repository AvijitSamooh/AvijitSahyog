import { Injectable } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service';
import type { PlatformHealthEventType, RecordHealthEventInput } from './platform-health.service';

@Injectable()
export class FirestorePlatformHealthService {
  constructor(private readonly firebase: FirebaseService) {}

  async recordEvent(input: RecordHealthEventInput) {
    const ref = this.firebase.db.collection('platformHealthEvents').doc();
    await ref.set({
      id: ref.id,
      type: input.type,
      statusCode: input.statusCode ?? null,
      route: input.route ? input.route.split('?')[0].slice(0, 200) : null,
      method: input.method ?? null,
      message: input.message ? input.message.replace(/\s+/g, ' ').slice(0, 500) : null,
      metadata: input.metadata ?? null,
      createdAt: Timestamp.now(),
    });
  }
}
