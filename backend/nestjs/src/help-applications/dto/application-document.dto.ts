import { IsEnum, IsUUID } from 'class-validator';

export enum ApplicationDocumentTypeDto {
  AADHAAR = 'AADHAAR',
  MARKSHEET = 'MARKSHEET',
  OTHER = 'OTHER',
}

export class ApplicationDocumentDto {
  @IsUUID('4')
  mediaId!: string;

  @IsEnum(ApplicationDocumentTypeDto)
  documentType!: ApplicationDocumentTypeDto;
}
