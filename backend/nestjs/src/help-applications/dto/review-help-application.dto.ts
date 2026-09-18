import { IsEnum, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export enum HelpApplicationDecisionDto {
  APPROVE = 'APPROVE',
  REJECT = 'REJECT',
  CLARIFICATION_REQUIRED = 'CLARIFICATION_REQUIRED',
  CONSIDER_FOR_SAMMAN = 'CONSIDER_FOR_SAMMAN',
  NOT_SELECTED = 'NOT_SELECTED',
}

export class ReviewHelpApplicationDto {
  @IsEnum(HelpApplicationDecisionDto)
  decision!: HelpApplicationDecisionDto;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  approvedAmount?: number;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  reason?: string;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  note?: string;
}