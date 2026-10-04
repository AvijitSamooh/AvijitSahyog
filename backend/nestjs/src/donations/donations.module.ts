import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { DonationsController } from './donations.controller';
import { DonationsService } from './donations.service';
import { FirestoreDonationsService } from './firestore-donations.service';

@Module({
  imports: [PrismaModule, FirebaseModule],
  controllers: [DonationsController],
  providers: [DonationsService, FirestoreDonationsService],
})
export class DonationsModule {}
