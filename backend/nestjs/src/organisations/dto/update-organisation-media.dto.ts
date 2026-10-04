import type { OrganisationMediaPurpose } from './attach-organisation-media.dto';
export interface UpdateOrganisationMediaDto { purpose?:OrganisationMediaPurpose; displayOrder?:number; isPrimary?:boolean; }
