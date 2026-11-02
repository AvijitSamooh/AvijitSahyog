import { MediaController } from './media.controller';

describe('MediaController', () => {
  let controller: MediaController;
  let mediaService: { uploadImage: jest.Mock };
  let storageService: { verifyConnection: jest.Mock };

  beforeEach(() => {
    mediaService = { uploadImage: jest.fn() };
    storageService = { verifyConnection: jest.fn() };
    controller = new MediaController(mediaService as never, storageService as never);
  });

  describe('verifyConnection', () => {
    it('verifies Firebase Storage connectivity', async () => {
      const previousBucket = process.env.FIREBASE_STORAGE_BUCKET;
      process.env.FIREBASE_STORAGE_BUCKET = 'avijit-sahyog.firebasestorage.app';
      await expect(controller.verifyConnection()).resolves.toEqual({
        status: 'ok',
        storage: 'firebase-storage',
        bucket: 'avijit-sahyog.firebasestorage.app',
      });
      expect(storageService.verifyConnection).toHaveBeenCalledTimes(1);
      if (previousBucket === undefined) delete process.env.FIREBASE_STORAGE_BUCKET;
      else process.env.FIREBASE_STORAGE_BUCKET = previousBucket;
    });

    it('propagates storage verification failures', async () => {
      storageService.verifyConnection.mockRejectedValue(new Error('Storage unavailable'));
      await expect(controller.verifyConnection()).rejects.toThrow('Storage unavailable');
    });
  });

  describe('uploadImage', () => {
    it('delegates uploaded files to MediaService', async () => {
      const file = {
        originalname: 'photo.jpg', mimetype: 'image/jpeg', size: 1024, buffer: Buffer.from('image'),
      } as Express.Multer.File;
      const uploadedMedia = { id: 'media-1', storageKey: 'uploads/media-1.webp' };
      mediaService.uploadImage.mockResolvedValue(uploadedMedia);
      await expect(controller.uploadImage(file)).resolves.toEqual(uploadedMedia);
      expect(mediaService.uploadImage).toHaveBeenCalledWith(file);
    });

    it('passes through validation failures', async () => {
      const file = {
        originalname: 'invalid.pdf', mimetype: 'application/pdf', size: 1024, buffer: Buffer.from('invalid'),
      } as Express.Multer.File;
      mediaService.uploadImage.mockRejectedValue(new Error('Only JPEG, PNG, and WebP images are allowed.'));
      await expect(controller.uploadImage(file)).rejects.toThrow('Only JPEG, PNG, and WebP images are allowed.');
    });
  });
});
