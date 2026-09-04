import { OrganisationMediaPurpose } from '@prisma/client';

export interface AttachOrganisationMediaDto {
  mediaId: string;
  purpose?: OrganisationMediaPurpose;
  displayOrder?: number;
  isPrimary?: boolean;
}
