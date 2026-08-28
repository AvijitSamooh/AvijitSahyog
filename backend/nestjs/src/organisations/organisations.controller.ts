import { Controller, Get, Param, Query } from '@nestjs/common';
import { OrganisationsService } from './organisations.service';

@Controller('organisations')
export class OrganisationsController {
  constructor(private readonly organisationsService: OrganisationsService) {}

  @Get()
  findAll(@Query('language') language?: string) {
    return this.organisationsService.findAll(language ?? 'en');
  }

  @Get(':slug')
  findOne(
    @Param('slug') slug: string,
    @Query('language') language?: string,
  ) {
    return this.organisationsService.findOne(slug, language ?? 'en');
  }
}
