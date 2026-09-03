import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import sharp from 'sharp';
import { randomUUID } from 'crypto';
import { R2StorageService } from './r2-storage.service';

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_UPLOAD_SIZE = 10 * 1024 * 1024;
const MAX_DIMENSION = 1920;

@Injectable()
export class MediaService {
  constructor(private readonly r2StorageService: R2StorageService) {}

  async uploadImage(file: Express.Multer.File, folder = 'uploads') {
    if (!file) {
      throw new BadRequestException('Image file is required.');
    }

    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        'Only JPEG, PNG, and WebP images are allowed.',
      );
    }

    if (file.size > MAX_UPLOAD_SIZE) {
      throw new BadRequestException('Image must be 10 MB or smaller.');
    }

    try {
      const image = sharp(file.buffer).rotate().resize({
        width: MAX_DIMENSION,
        height: MAX_DIMENSION,
        fit: 'inside',
        withoutEnlargement: true,
      });

      const metadata = await image.metadata();

      const processedBuffer = await image
        .webp({ quality: 82 })
        .toBuffer();

      const key = `${folder}/${randomUUID()}.webp`;

      await this.r2StorageService.upload(
        key,
        processedBuffer,
        'image/webp',
      );

      return {
        key,
        mimeType: 'image/webp',
        fileSize: processedBuffer.length,
        width: metadata.width ?? null,
        height: metadata.height ?? null,
      };
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }

      throw new InternalServerErrorException(
        'Unable to process and upload image.',
      );
    }
  }
}
