import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { AdminCausesController } from './admin-causes.controller';
import { CausesController } from './causes.controller';
import { CausesService } from './causes.service';
import { FirestoreCausesService } from './firestore-causes.service';

@Module({
  imports: [AuthModule, FirebaseModule],
  controllers: [CausesController, AdminCausesController],
  providers: [CausesService, FirestoreCausesService],
})
export class CausesModule {}
