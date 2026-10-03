import {
  BadRequestException,
  Injectable,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import sharp from 'sharp';
import { PrismaService } from '../prisma/prisma.service';
import { R2StorageService } from './r2-storage.service';

const ALLOWED_IMAGE_FORMATS = new Set(['jpeg', 'png', 'webp']);
const MAX_UPLOAD_SIZE = 10 * 1024 * 1024;
const MAX_DIMENSION = 1600;
const MAX_PROCESSED_SIZE = 1.5 * 1024 * 1024;

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

      let processedBuffer = await sharp(file.buffer)
        .rotate()
        .resize({
          width: MAX_DIMENSION,
          height: MAX_DIMENSION,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: 82 })
        .toBuffer();

      // Do not let a camera-original-sized image become a large R2 object.
      // Re-encode progressively only when needed so ordinary photos retain
      // better visual quality while oversized outputs are bounded.
      for (const quality of [76, 72, 68]) {
        if (processedBuffer.length <= MAX_PROCESSED_SIZE) break;
        processedBuffer = await sharp(file.buffer)
          .rotate()
          .resize({
            width: MAX_DIMENSION,
            height: MAX_DIMENSION,
            fit: 'inside',
            withoutEnlargement: true,
          })
          .webp({ quality })
          .toBuffer();
      }

      if (processedBuffer.length > MAX_PROCESSED_SIZE) {
        processedBuffer = await sharp(file.buffer)
          .rotate()
          .resize({
            width: 1400,
            height: 1400,
            fit: 'inside',
            withoutEnlargement: true,
          })
          .webp({ quality: 65 })
          .toBuffer();
      }

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
  async deleteUserImage(id: string, uploadedById: string) {
    const media = await this.prisma.media.findFirst({
      where: { id, uploadedById },
      select: {
        id: true,
        storageKey: true,
        _count: {
          select: {
            organisationMedia: true,
            beneficiaryMedia: true,
            helpApplicationMedia: true,
            certificatePhotoApplications: true,
            facePhotoApplications: true,
          },
        },
      },
    });
    if (!media) throw new NotFoundException('Image not found.');
    const refs = Object.values(media._count).reduce((sum, count) => sum + count, 0);
    if (refs > 0) {
      throw new BadRequestException('This image is still attached to an application and cannot be deleted.');
    }
    await this.r2StorageService.delete(media.storageKey);
    await this.prisma.media.delete({ where: { id: media.id } });
    return { id, deleted: true };
  }

}
