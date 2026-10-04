import type { BeneficiaryMediaPurpose } from './attach-beneficiary-media.dto';
export interface UpdateBeneficiaryMediaDto { purpose?:BeneficiaryMediaPurpose; displayOrder?:number; isPrimary?:boolean; }
