import { IsArray, IsNumber, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

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
}