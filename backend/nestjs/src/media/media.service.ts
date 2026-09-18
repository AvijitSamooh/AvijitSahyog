import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import sharp from 'sharp';
import { PrismaService } from '../prisma/prisma.service';
import { R2StorageService } from './r2-storage.service';

const ALLOWED_IMAGE_FORMATS = new Set(['jpeg', 'png', 'webp']);
const MAX_UPLOAD_SIZE = 10 * 1024 * 1024;
const MAX_DIMENSION = 1920;

@Injectable()
export class MediaService {
  constructor(
    private readonly r2StorageService: R2StorageService,
    private readonly prisma: PrismaService,
  ) {}

  async uploadImage(file: Express.Multer.File, folder = 'uploads', uploadedById?: string) {
    if (!file) {
      throw new BadRequestException('Image file is required.');
    }

    if (file.size > MAX_UPLOAD_SIZE) {
      throw new BadRequestException('Image must be 10 MB or smaller.');
    }

    try {
      let inputMetadata: sharp.Metadata;
      try {
        inputMetadata = await sharp(file.buffer).metadata();
      } catch (_) {
        throw new BadRequestException(
          'Only JPEG, PNG, and WebP images are allowed.',
        );
      }

      if (
        !inputMetadata.format ||
        !ALLOWED_IMAGE_FORMATS.has(inputMetadata.format)
      ) {
        throw new BadRequestException(
          'Only JPEG, PNG, and WebP images are allowed.',
        );
      }

      const processedBuffer = await sharp(file.buffer)
        .rotate()
        .resize({
          width: MAX_DIMENSION,
          height: MAX_DIMENSION,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 82 })
        .toBuffer();

      const metadata = await sharp(processedBuffer).metadata();
      const key = `${folder}/${randomUUID()}.webp`;

      await this.r2StorageService.upload(
        key,
        processedBuffer,
        'image/webp',
      );

      try {
        return await this.prisma.media.create({
          data: {
            ...(uploadedById ? { uploadedById } : {}),
            storageKey: key,
            mimeType: 'image/webp',
            fileSize: processedBuffer.length,
            width: metadata.width ?? null,
            height: metadata.height ?? null,
          },
        });
      } catch (error) {
        await this.r2StorageService.delete(key);
        throw error;
      }
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }

      if (error instanceof InternalServerErrorException) {
        throw error;
      }

      throw new InternalServerErrorException(
        'Unable to process and upload image.',
      );
    }
  }
}
