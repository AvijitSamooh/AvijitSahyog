import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';

import { AdminGuard } from '../auth/admin.guard';
import type { CreateOrganisationDto } from './dto/create-organisation.dto';
import type { UpdateOrganisationDto } from './dto/update-organisation.dto';
import { OrganisationsService } from './organisations.service';

@Controller('admin/organisations')
@UseGuards(AdminGuard)
export class AdminOrganisationsController {
  constructor(private readonly organisationsService: OrganisationsService) {}

  @Get()
  findAll() {
    return this.organisationsService.findAllForAdmin();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.organisationsService.findOneForAdmin(id);
  }

  @Post()
  create(@Body() dto: CreateOrganisationDto) {
    return this.organisationsService.create(dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateOrganisationDto) {
    return this.organisationsService.update(id, dto);
  }

  @Patch(':id/causes')
  updateCauses(@Param('id') id: string, @Body('causeIds') causeIds: string[]) {
    return this.organisationsService.updateCauses(id, causeIds ?? []);
  }

  @Patch(':id/activate')
  activate(@Param('id') id: string) {
    return this.organisationsService.setActive(id, true);
  }

  @Patch(':id/deactivate')
  deactivate(@Param('id') id: string) {
    return this.organisationsService.setActive(id, false);
  }
}
