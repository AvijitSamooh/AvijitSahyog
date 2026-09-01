import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';

import { AdminGuard } from '../auth/admin.guard';
import type { CreateCauseDto } from './dto/create-cause.dto';
import type { UpdateCauseDto } from './dto/update-cause.dto';
import { CausesService } from './causes.service';

@Controller('admin/causes')
@UseGuards(AdminGuard)
export class AdminCausesController {
  constructor(private readonly causesService: CausesService) {}

  @Get()
  findAll() {
    return this.causesService.findAllForAdmin();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.causesService.findOneForAdmin(id);
  }

  @Post()
  create(@Body() dto: CreateCauseDto) {
    return this.causesService.create(dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateCauseDto) {
    return this.causesService.update(id, dto);
  }

  @Patch(':id/activate')
  activate(@Param('id') id: string) {
    return this.causesService.setActive(id, true);
  }

  @Patch(':id/deactivate')
  deactivate(@Param('id') id: string) {
    return this.causesService.setActive(id, false);
  }
}
