import { IsArray, IsEnum, IsNumber, IsOptional, IsString, IsUUID, Max, MaxLength, Min } from 'class-validator';

export enum HelpApplicationTypeDto {
  EDUCATION_ASSISTANCE = 'EDUCATION_ASSISTANCE',
  MEDICAL_HELP = 'MEDICAL_HELP',
  PRATIBHA_SAMMAN = 'PRATIBHA_SAMMAN',
}

export class CreateHelpApplicationDto {
  @IsEnum(HelpApplicationTypeDto)
  type!: HelpApplicationTypeDto;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  requestedAmount?: number;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  clarification?: string;

  @IsArray()
  @IsUUID('4', { each: true })
  mediaIds!: string[];
}