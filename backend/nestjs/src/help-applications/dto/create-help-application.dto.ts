import { IsArray, IsDateString, IsEnum, IsNumber, IsOptional, IsString, IsUUID, Matches, Max, MaxLength, Min } from 'class-validator';
import { ApplicationDocumentDto } from './application-document.dto';

export enum HelpApplicationTypeDto {
  EDUCATION_ASSISTANCE = 'EDUCATION_ASSISTANCE',
  MEDICAL_HELP = 'MEDICAL_HELP',
  PRATIBHA_SAMMAN = 'PRATIBHA_SAMMAN',
}

export class CreateHelpApplicationDto {
  @IsEnum(HelpApplicationTypeDto)
  type!: HelpApplicationTypeDto;

  @IsString()
  @MaxLength(250)
  applicantName!: string;

  @IsString()
  @MaxLength(20)
  mobileNumber!: string;

  @IsOptional()
  @IsString()
  @MaxLength(320)
  email?: string;

  @IsString()
  @MaxLength(500)
  address!: string;

  @IsString()
  @MaxLength(100)
  city!: string;

  @IsString()
  @MaxLength(100)
  state!: string;

  @IsString()
  @MaxLength(10)
  pincode!: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100)
  overallPercentage!: number;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  requestedAmount?: number;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  clarification?: string;

  @IsOptional()
  @IsString()
  @MaxLength(250)
  motherName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(250)
  fatherName?: string;

  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  classStandard?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  schoolInstituteName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(10000)
  accomplishments?: string;

  @IsOptional()
  @IsUUID('4')
  certificatePhotoMediaId?: string;

  @IsUUID('4')
  facePhotoMediaId!: string;

  @IsArray()
  @IsUUID('4', { each: true })
  mediaIds!: string[];

  @IsOptional()
  @IsArray()
  documents?: ApplicationDocumentDto[];

  @IsArray()
  @IsString({ each: true })
  @Matches(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, { each: true })
  acceptedRuleIds!: string[];
}
