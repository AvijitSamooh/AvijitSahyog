import { Body, ConflictException, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';

import { AdminGuard } from '../auth/admin.guard';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { PrismaService } from '../prisma/prisma.service';
import type { CreateOrganisationDto } from './dto/create-organisation.dto';
import type { UpdateOrganisationDto } from './dto/update-organisation.dto';
import type { AttachOrganisationMediaDto } from './dto/attach-organisation-media.dto';
import type { UpdateOrganisationMediaDto } from './dto/update-organisation-media.dto';
import { OrganisationsService } from './organisations.service';

@Controller('admin/organisations')
@UseGuards(AdminGuard)
export class AdminOrganisationsController {
  constructor(
    private readonly organisationsService: OrganisationsService,
    private readonly prisma: PrismaService,
  ) {}

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
  async remove(
    @Param('id') id: string,
    @Req() request: Request & AuthenticatedRequest,
  ) {
    const organisation = await this.organisationsService.findOneForAdmin(id);

    const [allocationCount, beneficiaryCount] = await Promise.all([
      this.prisma.donationAllocation.count({ where: { organisationId: id } }),
      this.prisma.beneficiary.count({ where: { organisationId: id } }),
    ]);

    if (allocationCount > 0 || beneficiaryCount > 0) {
      throw new ConflictException(
        `This organisation cannot be deleted because it is linked to ${allocationCount} donation allocation(s) and ${beneficiaryCount} beneficiary record(s). Deactivate it instead.`,
      );
    }

    const actor = await this.prisma.user.findUnique({
      where: { firebaseUid: request.user.uid },
      select: { id: true },
    });
    if (!actor) {
      throw new ConflictException('Administrator account was not found.');
    }

    const displayName =
      organisation.translations.find((item: any) => item.language?.code === 'en')?.name ??
      organisation.translations[0]?.name ??
      organisation.slug;

    return this.prisma.$transaction(async (tx) => {
      await tx.organisation.delete({ where: { id } });

      await tx.auditLog.create({
        data: {
          action: 'USER_ROLE_CHANGED',
          actorUserId: actor.id,
          metadata: {
            eventType: 'ORGANISATION_DELETED',
            organisationId: id,
            organisationSlug: organisation.slug,
            organisationName: displayName,
          },
        },
      });

      return { id, deleted: true };
    });
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
