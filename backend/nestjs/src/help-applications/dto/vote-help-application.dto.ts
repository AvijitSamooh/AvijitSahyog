import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class VoteHelpApplicationDto {
  @IsInt()
  @Min(1)
  @Max(5)
  score!: number;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  comment?: string;
}