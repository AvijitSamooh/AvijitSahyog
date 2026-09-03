import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { R2StorageService } from './r2-storage.service';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [MediaController],
  providers: [MediaService, R2StorageService],
  exports: [MediaService, R2StorageService],
})
export class MediaModule {}
