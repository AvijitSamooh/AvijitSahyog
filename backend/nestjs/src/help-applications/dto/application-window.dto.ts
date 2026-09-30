import { IsDateString, IsEnum, IsOptional } from 'class-validator';
import { HelpApplicationTypeDto } from './create-help-application.dto';

export class StartApplicationWindowDto {
  @IsEnum(HelpApplicationTypeDto)
  type!: HelpApplicationTypeDto;

  @IsOptional()
  @IsDateString()
  startsAt?: string;
}
