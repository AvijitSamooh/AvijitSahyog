import { BeneficiaryMediaPurpose } from '@prisma/client';

export interface AttachBeneficiaryMediaDto {
  mediaId: string;
  purpose?: BeneficiaryMediaPurpose;
  displayOrder?: number;
  isPrimary?: boolean;
}
