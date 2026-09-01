import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class OrganisationTranslationDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(10)
  languageCode!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(250)
  name!: string;

  @IsOptional()
  @IsString()
  description?: string;
}
