import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { SuperAdminGuard } from '../auth/super-admin.guard';
import { PlatformDowntimeService } from './platform-downtime.service';

@Controller('platform-downtime')
export class PlatformDowntimeController {
  constructor(private readonly downtime: PlatformDowntimeService) {}

  @Get()
  get() {
    return this.downtime.get();
  }

  @Patch()
  @UseGuards(SuperAdminGuard)
  update(@Body() body: { enabled?: boolean; startTime?: string; endTime?: string; message?: string | null }) {
    return this.downtime.update(body);
  }
}
