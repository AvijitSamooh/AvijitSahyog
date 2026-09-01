import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { AdminBeneficiariesController } from './admin-beneficiaries.controller';
import { BeneficiariesController } from './beneficiaries.controller';
import { BeneficiariesService } from './beneficiaries.service';

@Module({
  imports: [AuthModule],
  controllers: [BeneficiariesController, AdminBeneficiariesController],
  providers: [BeneficiariesService],
})
export class BeneficiariesModule {}
