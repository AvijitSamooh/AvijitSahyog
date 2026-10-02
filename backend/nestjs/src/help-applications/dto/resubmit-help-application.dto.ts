import { IsArray, IsDateString, IsNumber, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export class ResubmitHelpApplicationDto {
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  requestedAmount?: number;

  @IsString()
  @MaxLength(5000)
  clarification!: string;

  @IsArray()
  @IsUUID('4', { each: true })
  mediaIds!: string[];

  @IsArray()
  @IsUUID('all', { each: true })
  acceptedRuleIds!: string[];

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
}
