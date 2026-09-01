import type { OrganisationTranslationDto } from './organisation-translation.dto';

export interface CreateOrganisationDto {
  slug: string;
  logoUrl?: string;
  websiteUrl?: string;
  phone?: string;
  email?: string;
  address?: string;
  city?: string;
  state?: string;
  country?: string;
  displayOrder?: number;
  translations: OrganisationTranslationDto[];
}
