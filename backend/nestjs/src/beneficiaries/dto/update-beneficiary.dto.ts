export interface UpdateBeneficiaryDto {
  name?: string;
  photoUrl?: string;
  story?: string;
  supportedYear?: number;
  contributionAmount?: number;
  causeId?: string;
  organisationId?: string | null;
  displayOrder?: number;
  isActive?: boolean;
}
