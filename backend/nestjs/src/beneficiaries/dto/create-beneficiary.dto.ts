export interface CreateBeneficiaryDto {
  name: string;
  photoUrl?: string;
  story?: string;
  supportedYear: number;
  contributionAmount: number;
  causeId: string;
  organisationId?: string;
  displayOrder?: number;
}
