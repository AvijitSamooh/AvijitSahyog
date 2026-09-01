import { CauseTranslationDto } from './cause-translation.dto';

export interface UpdateCauseDto {
  slug?: string;
  displayOrder?: number;
  isActive?: boolean;
  translations?: CauseTranslationDto[];
}
