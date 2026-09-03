import { MediaController } from './media.controller';

describe('MediaController', () => {
  let controller: MediaController;
  let mediaService: { uploadImage: jest.Mock };
  let r2StorageService: { verifyConnection: jest.Mock };

  beforeEach(() => {
    mediaService = {
      uploadImage: jest.fn(),
    };
    r2StorageService = {
      verifyConnection: jest.fn(),
    };

    controller = new MediaController(
      mediaService as never,
      r2StorageService as never,
    );
  });

  describe('verifyConnection', () => {
    it('verifies storage connectivity and returns storage status', async () => {
      const previousBucket = process.env.R2_BUCKET_NAME;
      process.env.R2_BUCKET_NAME = 'avijit-sahyog-media';

      await expect(controller.verifyConnection()).resolves.toEqual({
        status: 'ok',
        storage: 'cloudflare-r2',
        bucket: 'avijit-sahyog-media',
      });

      expect(r2StorageService.verifyConnection).toHaveBeenCalledTimes(1);
      process.env.R2_BUCKET_NAME = previousBucket;
    });

    it('propagates storage verification failures', async () => {
      r2StorageService.verifyConnection.mockRejectedValue(
        new Error('Storage unavailable'),
      );

      await expect(controller.verifyConnection()).rejects.toThrow(
        'Storage unavailable',
      );
    });
  });

  describe('uploadImage', () => {
    it('delegates the uploaded file to MediaService', async () => {
      const file = {
        originalname: 'photo.jpg',
        mimetype: 'image/jpeg',
        size: 1024,
        buffer: Buffer.from('image'),
      } as Express.Multer.File;

      const uploadedMedia = {
        id: 'media-1',
        storageKey: 'uploads/media-1.webp',
      };

      mediaService.uploadImage.mockResolvedValue(uploadedMedia);

      await expect(controller.uploadImage(file)).resolves.toEqual(uploadedMedia);

      expect(mediaService.uploadImage).toHaveBeenCalledWith(file);
    });

    it('passes through MediaService validation failures', async () => {
      const file = {
        originalname: 'invalid.pdf',
        mimetype: 'application/pdf',
        size: 1024,
        buffer: Buffer.from('invalid'),
      } as Express.Multer.File;

      mediaService.uploadImage.mockRejectedValue(
        new Error('Only JPEG, PNG, and WebP images are allowed.'),
      );

      await expect(controller.uploadImage(file)).rejects.toThrow(
        'Only JPEG, PNG, and WebP images are allowed.',
      );
    });
  });
});
