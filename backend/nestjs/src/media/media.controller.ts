import {
  Controller,
  Get,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { AdminGuard } from '../auth/admin.guard';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { MediaService } from './media.service';
import { R2StorageService } from './r2-storage.service';

@Controller('admin/media')
@UseGuards(AdminGuard)
export class MediaController {
  constructor(
    private readonly mediaService: MediaService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  @Get('verify')
  async verifyConnection() {
    await this.r2StorageService.verifyConnection();

    return {
      status: 'ok',
      storage: 'cloudflare-r2',
      bucket: process.env.R2_BUCKET_NAME,
    };
  }

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  async uploadImage(@UploadedFile() file: Express.Multer.File) {
    return this.mediaService.uploadImage(file);
  }

}


@Controller('media')
@UseGuards(FirebaseAuthGuard)
export class UserMediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  async uploadUserImage(@UploadedFile() file: Express.Multer.File) {
    return this.mediaService.uploadImage(file, 'applications');
  }
}
