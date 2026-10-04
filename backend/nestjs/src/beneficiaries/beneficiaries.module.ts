import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { AdminBeneficiariesController } from './admin-beneficiaries.controller';
import { BeneficiariesController } from './beneficiaries.controller';
import { BeneficiariesService } from './beneficiaries.service';
import { FirestoreBeneficiariesService } from './firestore-beneficiaries.service';

@Module({
  imports: [AuthModule, FirebaseModule],
  controllers: [BeneficiariesController, AdminBeneficiariesController],
  providers: [BeneficiariesService, FirestoreBeneficiariesService],
})
export class BeneficiariesModule {}
