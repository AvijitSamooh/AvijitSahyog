import { CauseTranslationDto } from './cause-translation.dto';

export interface CreateCauseDto {
  slug: string;
  displayOrder?: number;
  translations: CauseTranslationDto[];
}
