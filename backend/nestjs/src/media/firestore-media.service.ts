import { Injectable, NotFoundException } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service';

export type FirestoreMedia = {
  id: string;
  uploadedById: string | null;
  storageKey: string;
  mimeType: string;
  fileSize: number;
  width: number | null;
  height: number | null;
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class FirestoreMediaService {
  constructor(private readonly firebase: FirebaseService) {}

  async upsert(media: FirestoreMedia) {
    await this.firebase.db.collection('media').doc(media.id).set({
      ...media,
      createdAt: Timestamp.fromDate(media.createdAt),
      updatedAt: Timestamp.fromDate(media.updatedAt),
    }, { merge: true });
    return media;
  }

  async getById(id: string) {
    const snapshot = await this.firebase.db.collection('media').doc(id).get();
    if (!snapshot.exists) throw new NotFoundException('Image not found.');
    return snapshot.data() as FirestoreMedia;
  }

  async delete(id: string) {
    await this.firebase.db.collection('media').doc(id).delete();
  }
}
