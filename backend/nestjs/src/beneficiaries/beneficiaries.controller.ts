import { Controller, Get, Param, Query } from '@nestjs/common';
import { BeneficiariesService } from './beneficiaries.service';

@Controller('beneficiaries')
export class BeneficiariesController {
  constructor(private readonly service: BeneficiariesService) {}

  @Get()
  findAll(
    @Query('causeId') causeId?: string,
    @Query('year') year?: string,
    @Query('search') search?: string,
    @Query('sort') sort?: string,
  ) {
    return this.service.findAll({ causeId, year: year ? Number(year) : undefined, search, sort });
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }
}
