import { BadRequestException, Injectable, Optional } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service';
import { ANALYTICS_EVENT_NAMES, AnalyticsEventName } from './analytics.constants';

export const MAX_FIRESTORE_ANALYTICS_BATCH_SIZE = 50;

export type FirestoreAnalyticsInput = {
  clientId: string;
  sessionId: string;
  eventName: AnalyticsEventName;
  screenName?: string;
  interactionType?: string;
  target?: string;
  city?: string;
  language?: string;
  deviceType?: string;
};

@Injectable()
export class FirestoreAnalyticsService {
  constructor(private readonly firebase: FirebaseService) {}

  async trackBatch(inputs: FirestoreAnalyticsInput[]) {
    if (inputs.length === 0) return;
    if (inputs.length > MAX_FIRESTORE_ANALYTICS_BATCH_SIZE) {
      throw new BadRequestException(
        `Analytics batch cannot exceed ${MAX_FIRESTORE_ANALYTICS_BATCH_SIZE} events.`,
      );
    }

    for (const input of inputs) this.validate(input);

    const batch = this.firebase.db.batch();
    for (const input of inputs) {
      const ref = this.firebase.db.collection('analyticsEvents').doc();
      batch.set(ref, {
        id: ref.id,
        ...input,
        createdAt: Timestamp.now(),
      });
    }
    await batch.commit();
  }

  private validate(input: FirestoreAnalyticsInput) {
    if (!ANALYTICS_EVENT_NAMES.includes(input.eventName)) {
      throw new BadRequestException('Unsupported analytics event.');
    }
    if (
      !/^[a-f0-9-]{16,64}$/i.test(input.clientId) ||
      !/^[a-f0-9-]{16,64}$/i.test(input.sessionId)
    ) {
      throw new BadRequestException('Invalid analytics identifiers.');
    }
  }
}
