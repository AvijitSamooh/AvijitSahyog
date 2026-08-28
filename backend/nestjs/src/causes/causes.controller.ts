import { Controller, Get, Param, Query } from '@nestjs/common';
import { CausesService } from './causes.service';

@Controller('causes')
export class CausesController {
  constructor(private readonly causesService: CausesService) {}

  @Get()
  findAll(@Query('language') language?: string) {
    return this.causesService.findAll(language ?? 'en');
  }

  @Get(':slug')
  findOne(@Param('slug') slug: string, @Query('language') language?: string) {
    return this.causesService.findOne(slug, language ?? 'en');
  }
}
