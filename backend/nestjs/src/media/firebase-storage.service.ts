import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { getStorage } from 'firebase-admin/storage';

@Injectable()
export class FirebaseStorageService {
  private readonly bucketName = process.env.FIREBASE_STORAGE_BUCKET;

  private getBucket() {
    if (!this.bucketName) {
      throw new InternalServerErrorException(
        'Firebase Storage is not configured. Set FIREBASE_STORAGE_BUCKET to the bucket name from Firebase Console.',
      );
    }
    try {
      return getStorage().bucket(this.bucketName);
    } catch {
      throw new InternalServerErrorException(
        'Unable to initialize Firebase Storage. Verify Firebase Admin credentials and FIREBASE_STORAGE_BUCKET.',
      );
    }
  }

  async verifyConnection(): Promise<void> {
    try {
      const [exists] = await this.getBucket().exists();
      if (!exists) {
        throw new Error('Configured Firebase Storage bucket does not exist.');
      }
    } catch (error) {
      if (error instanceof InternalServerErrorException) throw error;
      throw new InternalServerErrorException(
        'Unable to connect to Firebase Storage bucket. Verify the bucket name and service-account permissions.',
      );
    }
  }

  async upload(key: string, body: Buffer, contentType: string): Promise<void> {
    try {
      await this.getBucket().file(key).save(body, {
        resumable: false,
        metadata: { contentType },
      });
    } catch (error) {
      if (error instanceof InternalServerErrorException) throw error;
      throw new InternalServerErrorException('Unable to upload image to Firebase Storage.');
    }
  }

  async download(key: string): Promise<Buffer> {
    try {
      const [contents] = await this.getBucket().file(key).download();
      return contents;
    } catch (error) {
      if (error instanceof InternalServerErrorException) throw error;
      throw new InternalServerErrorException('Unable to download image from Firebase Storage.');
    }
  }

  async delete(key: string): Promise<void> {
    try {
      await this.getBucket().file(key).delete({ ignoreNotFound: true });
    } catch (error) {
      if (error instanceof InternalServerErrorException) throw error;
      throw new InternalServerErrorException('Unable to delete image from Firebase Storage.');
    }
  }
}
