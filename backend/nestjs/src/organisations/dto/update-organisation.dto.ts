import type { OrganisationTranslationDto } from './organisation-translation.dto';

export interface UpdateOrganisationDto {
  slug?: string;
  logoUrl?: string;
  websiteUrl?: string;
  phone?: string;
  mobileNumber?: string;
  email?: string;
  address?: string;
  city?: string;
  state?: string;
  country?: string;
  isActive?: boolean;
  displayOrder?: number;
  translations?: OrganisationTranslationDto[];
}
