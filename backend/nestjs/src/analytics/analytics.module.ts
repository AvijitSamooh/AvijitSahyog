import { Module } from '@nestjs/common';
import { FirebaseModule } from '../firebase/firebase.module';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { FirestoreAnalyticsService } from './firestore-analytics.service';
@Module({ imports:[FirebaseModule], controllers:[AnalyticsController], providers:[FirestoreAnalyticsService,{provide:AnalyticsService,useExisting:FirestoreAnalyticsService}], exports:[AnalyticsService] })
export class AnalyticsModule {}
