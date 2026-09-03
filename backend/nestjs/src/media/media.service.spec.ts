import {
  BadRequestException,
  InternalServerErrorException,
} from '@nestjs/common';
import sharp from 'sharp';
import { MediaService } from './media.service';

describe('MediaService', () => {
  let service: MediaService;
  let r2StorageService: { upload: jest.Mock; delete: jest.Mock };
  let prisma: { media: { create: jest.Mock } };

  beforeEach(() => {
    r2StorageService = {
      upload: jest.fn(),
      delete: jest.fn(),
    };
    prisma = {
      media: {
        create: jest.fn(),
      },
    };

    service = new MediaService(r2StorageService as never, prisma as never);
  });

  const createFile = (
    overrides: Partial<Express.Multer.File> = {},
  ): Express.Multer.File =>
    ({
      buffer: Buffer.from('not-used-for-validation'),
      mimetype: 'image/jpeg',
      size: 1024,
      ...overrides,
    }) as Express.Multer.File;

  it('rejects a missing file', async () => {
    await expect(service.uploadImage(undefined as never)).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(r2StorageService.upload).not.toHaveBeenCalled();
  });

  it('rejects unsupported MIME types', async () => {
    await expect(
      service.uploadImage(createFile({ mimetype: 'application/pdf' })),
    ).rejects.toBeInstanceOf(BadRequestException);

    expect(r2StorageService.upload).not.toHaveBeenCalled();
  });

  it('rejects files larger than 10 MB', async () => {
    await expect(
      service.uploadImage(createFile({ size: 10 * 1024 * 1024 + 1 })),
    ).rejects.toBeInstanceOf(BadRequestException);

    expect(r2StorageService.upload).not.toHaveBeenCalled();
  });

  it('processes a valid image, uploads WebP, and persists metadata', async () => {
    const input = await sharp({
      create: {
        width: 2400,
        height: 1200,
        channels: 3,
        background: { r: 255, g: 255, b: 255 },
      },
    })
      .jpeg()
      .toBuffer();

    const persistedMedia = {
      id: 'media-1',
      storageKey: 'uploads/test.webp',
      mimeType: 'image/webp',
      fileSize: 123,
      width: 1920,
      height: 960,
    };

    prisma.media.create.mockResolvedValue(persistedMedia);

    await expect(
      service.uploadImage(
        createFile({
          buffer: input,
          size: input.length,
        }),
      ),
    ).resolves.toEqual(persistedMedia);

    expect(r2StorageService.upload).toHaveBeenCalledWith(
      expect.stringMatching(/^uploads\/.+\.webp$/),
      expect.any(Buffer),
      'image/webp',
    );

    const uploadedBuffer = r2StorageService.upload.mock.calls[0][1] as Buffer;
    const metadata = await sharp(uploadedBuffer).metadata();

    expect(metadata.format).toBe('webp');
    expect(metadata.width).toBe(1920);
    expect(metadata.height).toBe(960);

    expect(prisma.media.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        storageKey: expect.stringMatching(/^uploads\/.+\.webp$/),
        mimeType: 'image/webp',
        width: 1920,
        height: 960,
        fileSize: uploadedBuffer.length,
      }),
    });
  });

  it('uses the requested storage folder', async () => {
    const input = await sharp({
      create: {
        width: 100,
        height: 100,
        channels: 3,
        background: { r: 255, g: 255, b: 255 },
      },
    })
      .png()
      .toBuffer();

    prisma.media.create.mockResolvedValue({ id: 'media-1' });

    await service.uploadImage(
      createFile({
        buffer: input,
        mimetype: 'image/png',
        size: input.length,
      }),
      'organisations',
    );

    expect(r2StorageService.upload).toHaveBeenCalledWith(
      expect.stringMatching(/^organisations\/.+\.webp$/),
      expect.any(Buffer),
      'image/webp',
    );
  });

  it('deletes the R2 object when database persistence fails', async () => {
    const input = await sharp({
      create: {
        width: 100,
        height: 100,
        channels: 3,
        background: { r: 255, g: 255, b: 255 },
      },
    })
      .jpeg()
      .toBuffer();

    prisma.media.create.mockRejectedValue(new Error('Database unavailable'));

    await expect(
      service.uploadImage(
        createFile({
          buffer: input,
          size: input.length,
        }),
      ),
    ).rejects.toBeInstanceOf(InternalServerErrorException);

    expect(r2StorageService.delete).toHaveBeenCalledWith(
      expect.stringMatching(/^uploads\/.+\.webp$/),
    );
  });

  it('returns an internal error when R2 upload fails', async () => {
    const input = await sharp({
      create: {
        width: 100,
        height: 100,
        channels: 3,
        background: { r: 255, g: 255, b: 255 },
      },
    })
      .jpeg()
      .toBuffer();

    r2StorageService.upload.mockRejectedValue(new Error('R2 unavailable'));

    await expect(
      service.uploadImage(
        createFile({
          buffer: input,
          size: input.length,
        }),
      ),
    ).rejects.toBeInstanceOf(InternalServerErrorException);

    expect(prisma.media.create).not.toHaveBeenCalled();
  });
});
