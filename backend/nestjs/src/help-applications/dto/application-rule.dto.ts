import { IsArray, IsBoolean, IsEnum, IsInt, IsOptional, IsString, Max, MaxLength, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { HelpApplicationTypeDto } from './create-help-application.dto';

export const SUPPORTED_RULE_LANGUAGES = ['en', 'hi', 'mr', 'gu'] as const;
export type SupportedRuleLanguage = typeof SUPPORTED_RULE_LANGUAGES[number];

export class ApplicationRuleTranslationDto {
  @IsString()
  language!: SupportedRuleLanguage;

  @IsString()
  @MaxLength(5000)
  text!: string;
}

export class CreateApplicationRuleDto {
  @IsEnum(HelpApplicationTypeDto)
  type!: HelpApplicationTypeDto;

  @IsInt()
  @Min(0)
  @Max(999)
  displayOrder!: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ApplicationRuleTranslationDto)
  translations!: ApplicationRuleTranslationDto[];
}

export class UpdateApplicationRuleDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(999)
  displayOrder?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ApplicationRuleTranslationDto)
  translations!: ApplicationRuleTranslationDto[];
}

export class PublicApplicationRulesQueryDto {
  @IsOptional()
  @IsString()
  language?: string;
}

export function validateRuleTranslations(translations: ApplicationRuleTranslationDto[]) {
  const values = new Map(translations.map((item) => [item.language, item.text.trim()]));
  const missing = SUPPORTED_RULE_LANGUAGES.filter((language) => !values.get(language));
  if (missing.length > 0) throw new Error('Translations are required for: ' + missing.join(', '));
  return SUPPORTED_RULE_LANGUAGES.map((language) => ({ language, text: values.get(language)! }));
}
