import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { FirestoreAnalyticsService } from './firestore-analytics.service';
@Module({ imports: [PrismaModule, FirebaseModule], controllers: [AnalyticsController], providers: [AnalyticsService, FirestoreAnalyticsService], exports: [AnalyticsService] })
export class AnalyticsModule {}
