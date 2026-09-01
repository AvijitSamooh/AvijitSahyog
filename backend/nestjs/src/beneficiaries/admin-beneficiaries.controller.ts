import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';

import { AdminGuard } from '../auth/admin.guard';
import { BeneficiariesService } from './beneficiaries.service';
import type { CreateBeneficiaryDto } from './dto/create-beneficiary.dto';
import type { UpdateBeneficiaryDto } from './dto/update-beneficiary.dto';

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

  @Patch(':id/activate')
  activate(@Param('id') id: string) {
    return this.service.setActive(id, true);
  }

  @Patch(':id/deactivate')
  deactivate(@Param('id') id: string) {
    return this.service.setActive(id, false);
  }
}
