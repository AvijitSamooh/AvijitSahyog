import { CauseTranslationDto } from './cause-translation.dto';

export interface UpdateCauseDto {
  slug?: string;
  parentId?: string | null;
  displayOrder?: number;
  isActive?: boolean;
  translations?: CauseTranslationDto[];
}
