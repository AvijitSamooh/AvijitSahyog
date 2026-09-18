import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';

import { AdminGuard } from '../auth/admin.guard';
import { BeneficiariesService } from './beneficiaries.service';
import type { CreateBeneficiaryDto } from './dto/create-beneficiary.dto';
import type { UpdateBeneficiaryDto } from './dto/update-beneficiary.dto';
import type { AttachBeneficiaryMediaDto } from './dto/attach-beneficiary-media.dto';
import type { UpdateBeneficiaryMediaDto } from './dto/update-beneficiary-media.dto';

@Controller('admin/beneficiaries')
@UseGuards(AdminGuard)
export class AdminBeneficiariesController {
  constructor(private readonly service: BeneficiariesService) {}

  @Get()
  findAll() {
    return this.service.findAllForAdmin();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOneForAdmin(id);
  }

  @Post()
  create(@Body() dto: CreateBeneficiaryDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateBeneficiaryDto) {
    return this.service.update(id, dto);
  }

  @Get(':id/media')
  listMedia(@Param('id') id: string) {
    return this.service.listMedia(id);
  }

  @Post(':id/media')
  attachMedia(@Param('id') id: string, @Body() dto: AttachBeneficiaryMediaDto) {
    return this.service.attachMedia(id, dto);
  }

  @Patch(':id/media/:mediaId')
  updateMedia(
    @Param('id') id: string,
    @Param('mediaId') mediaId: string,
    @Body() dto: UpdateBeneficiaryMediaDto,
  ) {
    return this.service.updateMedia(id, mediaId, dto);
  }

  @Delete(':id/media/:mediaId')
  removeMedia(@Param('id') id: string, @Param('mediaId') mediaId: string) {
    return this.service.removeMedia(id, mediaId);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.remove(id);
  }

  @Patch(':id/activate')
  activate(@Param('id') id: string) {
    return this.service.setActive(id, true);
  }

  @Patch(':id/deactivate')
  deactivate(@Param('id') id: string) {
    return this.service.setActive(id, false);
  }
}
