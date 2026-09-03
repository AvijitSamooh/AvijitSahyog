import { InternalServerErrorException } from '@nestjs/common';
import {
  DeleteObjectCommand,
  HeadBucketCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { R2StorageService } from './r2-storage.service';

describe('R2StorageService', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.restoreAllMocks();
    process.env = {
      ...originalEnv,
      R2_ENDPOINT: 'https://account-id.r2.cloudflarestorage.com',
      R2_ACCESS_KEY_ID: 'access-key',
      R2_SECRET_ACCESS_KEY: 'secret-key',
      R2_BUCKET_NAME: 'test-bucket',
    };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('allows application bootstrap without configuration but fails when storage is used', async () => {
    delete process.env.R2_BUCKET_NAME;
    const service = new R2StorageService();

    await expect(service.verifyConnection()).rejects.toBeInstanceOf(
      InternalServerErrorException,
    );
  });

  it('verifies bucket connectivity', async () => {
    const service = new R2StorageService();
    const send = jest
      .spyOn(S3Client.prototype, 'send')
      .mockResolvedValue({} as never);

    await expect(service.verifyConnection()).resolves.toBeUndefined();
    expect(send).toHaveBeenCalledWith(expect.any(HeadBucketCommand));
  });

  it('wraps bucket connectivity failures', async () => {
    const service = new R2StorageService();
    jest.spyOn(S3Client.prototype, 'send').mockRejectedValue(
      new Error('Connection failed'),
    );

    await expect(service.verifyConnection()).rejects.toBeInstanceOf(
      InternalServerErrorException,
    );
  });

  it('uploads an object with the expected metadata', async () => {
    const service = new R2StorageService();
    const send = jest
      .spyOn(S3Client.prototype, 'send')
      .mockResolvedValue({} as never);
    const body = Buffer.from('image');

    await service.upload('uploads/test.webp', body, 'image/webp');

    expect(send).toHaveBeenCalledWith(expect.any(PutObjectCommand));
    const command = send.mock.calls[0][0] as PutObjectCommand;
    expect(command.input).toEqual({
      Bucket: 'test-bucket',
      Key: 'uploads/test.webp',
      Body: body,
      ContentType: 'image/webp',
    });
  });

  it('deletes an object by key', async () => {
    const service = new R2StorageService();
    const send = jest
      .spyOn(S3Client.prototype, 'send')
      .mockResolvedValue({} as never);

    await service.delete('uploads/test.webp');

    expect(send).toHaveBeenCalledWith(expect.any(DeleteObjectCommand));
    const command = send.mock.calls[0][0] as DeleteObjectCommand;
    expect(command.input).toEqual({
      Bucket: 'test-bucket',
      Key: 'uploads/test.webp',
    });
  });
});
