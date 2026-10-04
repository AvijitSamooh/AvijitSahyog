import { BadRequestException, Injectable } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service';

export type PlatformDowntime = {
  enabled: boolean;
  startTime: string;
  endTime: string;
  message: string | null;
  updatedAt: string | null;
};

const COLLECTION = 'platformSettings';
const DOCUMENT = 'downtime';

@Injectable()
export class PlatformDowntimeService {
  private cached?: { value: PlatformDowntime; expiresAt: number };
  private static readonly CACHE_MS = 30_000;

  constructor(private readonly firebase: FirebaseService) {}

  async get(): Promise<PlatformDowntime> {
    if (this.cached && this.cached.expiresAt > Date.now()) {
      return this.cached.value;
    }

    const snapshot = await this.firebase.db.collection(COLLECTION).doc(DOCUMENT).get();
    if (!snapshot.exists) {
      const value = {
        enabled: false,
        startTime: '21:00',
        endTime: '08:00',
        message: null,
        updatedAt: null,
      };
      this.cached = { value, expiresAt: Date.now() + PlatformDowntimeService.CACHE_MS };
      return value;
    }

    const data = snapshot.data() ?? {};
    const updatedAt = data.updatedAt instanceof Timestamp ? data.updatedAt.toDate().toISOString() : null;
    const value = {
      enabled: data.enabled === true,
      startTime: this.validateTime(String(data.startTime ?? '21:00')),
      endTime: this.validateTime(String(data.endTime ?? '08:00')),
      message: data.message == null ? null : String(data.message),
      updatedAt,
    };
    this.cached = { value, expiresAt: Date.now() + PlatformDowntimeService.CACHE_MS };
    return value;
  }

  async update(input: {
    enabled?: boolean;
    startTime?: string;
    endTime?: string;
    message?: string | null;
  }): Promise<PlatformDowntime> {
    const current = await this.get();
    const next = {
      enabled: input.enabled ?? current.enabled,
      startTime: this.validateTime(input.startTime ?? current.startTime),
      endTime: this.validateTime(input.endTime ?? current.endTime),
      message: input.message === undefined ? current.message : this.normalizeMessage(input.message),
      updatedAt: Timestamp.now(),
    };

    await this.firebase.db.collection(COLLECTION).doc(DOCUMENT).set(next, { merge: true });
    this.cached = undefined;
    return this.get();
  }

  private validateTime(value: string): string {
    const match = /^(\d{2}):(\d{2})$/.exec(value.trim());
    if (!match) throw new BadRequestException('Time must use HH:mm format.');
    const hour = Number(match[1]);
    const minute = Number(match[2]);
    if (hour > 23 || minute > 59) {
      throw new BadRequestException('Time must use a valid 24-hour clock value.');
    }
    return value;
  }

  private normalizeMessage(value: string | null): string | null {
    if (value == null || value.trim() === '') return null;
    return value.trim().slice(0, 300);
  }
}
