import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';

import { AdminGuard } from '../auth/admin.guard';
import type { AuthenticatedRequest } from '../auth/auth.types';
import type { CreateOrganisationDto } from './dto/create-organisation.dto';
import type { UpdateOrganisationDto } from './dto/update-organisation.dto';
import type { AttachOrganisationMediaDto } from './dto/attach-organisation-media.dto';
import type { UpdateOrganisationMediaDto } from './dto/update-organisation-media.dto';
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

  @Get(':id/media')
  listMedia(@Param('id') id: string) {
    return this.organisationsService.listMedia(id);
  }

  @Post(':id/media')
  attachMedia(@Param('id') id: string, @Body() dto: AttachOrganisationMediaDto) {
    return this.organisationsService.attachMedia(id, dto);
  }

  @Patch(':id/media/:mediaId')
  updateMedia(
    @Param('id') id: string,
    @Param('mediaId') mediaId: string,
    @Body() dto: UpdateOrganisationMediaDto,
  ) {
    return this.organisationsService.updateMedia(id, mediaId, dto);
  }

  @Delete(':id/media/:mediaId')
  removeMedia(@Param('id') id: string, @Param('mediaId') mediaId: string) {
    return this.organisationsService.removeMedia(id, mediaId);
  }

  @Delete(':id')
  remove(
    @Param('id') id: string,
    @Req() request: Request & AuthenticatedRequest,
  ) {
    return this.organisationsService.removeOrDeactivate(id, request.user.uid);
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
