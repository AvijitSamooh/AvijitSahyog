import { CauseTranslationDto } from './cause-translation.dto';

export interface CreateCauseDto {
  slug: string;
  parentId?: string | null;
  displayOrder?: number;
  translations: CauseTranslationDto[];
}
