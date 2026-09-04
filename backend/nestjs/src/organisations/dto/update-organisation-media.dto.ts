import { OrganisationMediaPurpose } from '@prisma/client';

export interface UpdateOrganisationMediaDto {
  purpose?: OrganisationMediaPurpose;
  displayOrder?: number;
  isPrimary?: boolean;
}
