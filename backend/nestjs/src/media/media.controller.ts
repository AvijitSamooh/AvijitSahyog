import { Controller, Get, UseGuards } from '@nestjs/common';
import { AdminGuard } from '../auth/admin.guard';
import { R2StorageService } from './r2-storage.service';

@Controller('admin/media')
@UseGuards(AdminGuard)
export class MediaController {
  constructor(private readonly r2StorageService: R2StorageService) {}

  @Get('verify')
  async verifyConnection() {
    await this.r2StorageService.verifyConnection();

    return {
      status: 'ok',
      storage: 'cloudflare-r2',
      bucket: process.env.R2_BUCKET_NAME,
    };
  }
}
