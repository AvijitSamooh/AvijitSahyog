import { BeneficiaryMediaPurpose } from '@prisma/client';

export interface UpdateBeneficiaryMediaDto {
  purpose?: BeneficiaryMediaPurpose;
  displayOrder?: number;
  isPrimary?: boolean;
}
