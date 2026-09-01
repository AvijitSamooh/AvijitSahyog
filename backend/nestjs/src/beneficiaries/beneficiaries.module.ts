import { Module } from '@nestjs/common';
import { AdminBeneficiariesController } from './admin-beneficiaries.controller';
import { BeneficiariesController } from './beneficiaries.controller';
import { BeneficiariesService } from './beneficiaries.service';

@Module({ controllers: [BeneficiariesController, AdminBeneficiariesController], providers: [BeneficiariesService] })
export class BeneficiariesModule {}
