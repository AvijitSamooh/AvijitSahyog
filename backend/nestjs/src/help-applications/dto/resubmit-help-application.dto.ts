import { IsArray, IsDateString, IsNumber, IsOptional, IsString, IsUUID, Matches, MaxLength, Min } from 'class-validator';

export class ResubmitHelpApplicationDto {
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100)
  overallPercentage!: number;

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
  @IsString({ each: true })
  @Matches(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, { each: true })
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
