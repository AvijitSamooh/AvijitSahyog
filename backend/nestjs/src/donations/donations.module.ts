import { Module } from '@nestjs/common';
import { FirebaseModule } from '../firebase/firebase.module';
import { DonationsController } from './donations.controller';
import { DonationsService } from './donations.service';
import { FirestoreDonationsService } from './firestore-donations.service';
@Module({ imports:[FirebaseModule], controllers:[DonationsController], providers:[FirestoreDonationsService,{provide:DonationsService,useExisting:FirestoreDonationsService}] })
export class DonationsModule {}
