import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { AdminOrganisationsController } from './admin-organisations.controller';
import { OrganisationsController } from './organisations.controller';
import { OrganisationsService } from './organisations.service';
import { FirestoreOrganisationsService } from './firestore-organisations.service';

@Module({
  imports: [AuthModule, FirebaseModule],
  controllers: [OrganisationsController, AdminOrganisationsController],
  providers: [FirestoreOrganisationsService, { provide: OrganisationsService, useExisting: FirestoreOrganisationsService }],
})
export class OrganisationsModule {}
