export type BeneficiaryMediaPurpose = 'PROFILE' | 'GALLERY';
export interface AttachBeneficiaryMediaDto { mediaId:string; purpose?:BeneficiaryMediaPurpose; displayOrder?:number; isPrimary?:boolean; }
