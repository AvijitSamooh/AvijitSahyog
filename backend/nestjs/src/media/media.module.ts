import { Module } from '@nestjs/common';
import { MediaController } from './media.controller';
import { R2StorageService } from './r2-storage.service';

@Module({
  controllers: [MediaController],
  providers: [R2StorageService],
  exports: [R2StorageService],
})
export class MediaModule {}
