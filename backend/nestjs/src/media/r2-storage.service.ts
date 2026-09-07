import { Injectable, InternalServerErrorException } from '@nestjs/common';
import {
  DeleteObjectCommand,
  HeadBucketCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';

@Injectable()
export class R2StorageService {
  private readonly client: S3Client;
  private readonly bucketName?: string;

  constructor() {
    const endpoint = process.env.R2_ENDPOINT;
    const accessKeyId = process.env.R2_ACCESS_KEY_ID;
    const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;
    this.bucketName = process.env.R2_BUCKET_NAME;

    this.client = new S3Client({
      region: 'auto',
      ...(endpoint ? { endpoint } : {}),
      ...(accessKeyId && secretAccessKey
        ? {
            credentials: {
              accessKeyId,
              secretAccessKey,
            },
          }
        : {}),
    });
  }

  private getBucketName(): string {
    if (!this.bucketName) {
      throw new InternalServerErrorException(
        'Cloudflare R2 is not configured. Check R2_ENDPOINT, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, and R2_BUCKET_NAME.',
      );
    }

    if (
      !process.env.R2_ENDPOINT ||
      !process.env.R2_ACCESS_KEY_ID ||
      !process.env.R2_SECRET_ACCESS_KEY
    ) {
      throw new InternalServerErrorException(
        'Cloudflare R2 is not configured. Check R2_ENDPOINT, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, and R2_BUCKET_NAME.',
      );
    }

    return this.bucketName;
  }

  async verifyConnection(): Promise<void> {
    try {
      await this.client.send(
        new HeadBucketCommand({
          Bucket: this.getBucketName(),
        }),
      );
    } catch (error) {
      if (error instanceof InternalServerErrorException) {
        throw error;
      }

      throw new InternalServerErrorException(
        'Unable to connect to Cloudflare R2 bucket.',
      );
    }
  }

  async upload(
    key: string,
    body: Buffer,
    contentType: string,
  ): Promise<void> {
    try {
      await this.client.send(
        new PutObjectCommand({
          Bucket: this.getBucketName(),
          Key: key,
          Body: body,
          ContentType: contentType,
        }),
      );
    } catch (error) {
      if (error instanceof InternalServerErrorException) throw error;
      const detail = error instanceof Error ? error.message : 'Unknown storage error';
      throw new InternalServerErrorException(
        `Unable to upload image to Cloudflare R2: ${detail}`,
      );
    }
  }

  async delete(key: string): Promise<void> {
    await this.client.send(
      new DeleteObjectCommand({
        Bucket: this.getBucketName(),
        Key: key,
      }),
    );
  }
}
