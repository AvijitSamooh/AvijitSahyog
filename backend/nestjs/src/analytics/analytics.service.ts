import { FirestoreAnalyticsService, MAX_FIRESTORE_ANALYTICS_BATCH_SIZE, type FirestoreAnalyticsInput } from './firestore-analytics.service';

export const MAX_ANALYTICS_BATCH_SIZE = MAX_FIRESTORE_ANALYTICS_BATCH_SIZE;
export type TrackAnalyticsEventInput = FirestoreAnalyticsInput;

export class AnalyticsService extends FirestoreAnalyticsService {
  async track(input: TrackAnalyticsEventInput) {
    return this.trackBatch([input]);
  }
}
