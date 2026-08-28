import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import type { CreateDonationDto } from './dto/create-donation.dto';
import { DonationsService } from './donations.service';

@Controller('donations')
export class DonationsController {
  constructor(private readonly donationsService: DonationsService) {}

  @Post()
  create(@Body() input: CreateDonationDto) {
    return this.donationsService.create(input);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.donationsService.findOne(id);
  }
}
