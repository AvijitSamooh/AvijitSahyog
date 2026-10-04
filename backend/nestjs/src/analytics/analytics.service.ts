import { FirestoreAnalyticsService } from './firestore-analytics.service';
export class AnalyticsService extends FirestoreAnalyticsService {
  async track(input: any) { return this.trackBatch([input]); }
}
