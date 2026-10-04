export type OrganisationMediaPurpose = 'LOGO' | 'GALLERY';
export interface AttachOrganisationMediaDto { mediaId:string; purpose?:OrganisationMediaPurpose; displayOrder?:number; isPrimary?:boolean; }
