import { BadRequestException, Injectable } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service';

export type PlatformDowntimeSettings = {
  enabled: boolean;
  startTime: string;
  endTime: string;
  message: string | null;
  updatedAt: string | null;
  updatedBy: string | null;
};

const DEFAULTS: PlatformDowntimeSettings = {
  enabled: false,
  startTime: '21:00',
  endTime: '08:00',
  message: null,
  updatedAt: null,
  updatedBy: null,
};

@Injectable()
export class PlatformSettingsService {
  private static readonly COLLECTION = 'platformSettings';
  private static readonly DOCUMENT = 'serviceWindow';

  constructor(private readonly firebase: FirebaseService) {}

  async getDowntime(): Promise<PlatformDowntimeSettings> {
    const snapshot = await this.firebase.db.collection(PlatformSettingsService.COLLECTION).doc(PlatformSettingsService.DOCUMENT).get();
    if (!snapshot.exists) return DEFAULTS;
    const data = snapshot.data() ?? {};
    return {
      enabled: data.enabled === true,
      startTime: typeof data.startTime === 'string' ? data.startTime : DEFAULTS.startTime,
      endTime: typeof data.endTime === 'string' ? data.endTime : DEFAULTS.endTime,
      message: typeof data.message === 'string' ? data.message : null,
      updatedAt: this.timestamp(data.updatedAt),
      updatedBy: typeof data.updatedBy === 'string' ? data.updatedBy : null,
    };
  }

  async updateDowntime(input: { enabled: boolean; startTime: string; endTime: string; message?: string | null }, actorUserId: string) {
    this.validateTime(input.startTime);
    this.validateTime(input.endTime);
    const message = input.message?.trim() || null;
    if (message && message.length > 500) throw new BadRequestException('Downtime message cannot exceed 500 characters.');

    await this.firebase.db.collection(PlatformSettingsService.COLLECTION).doc(PlatformSettingsService.DOCUMENT).set({
      enabled: input.enabled,
      startTime: input.startTime,
      endTime: input.endTime,
      message,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: actorUserId,
    }, { merge: true });

    return this.getDowntime();
  }

  private validateTime(value: string) {
    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(value)) {
      throw new BadRequestException('Time must use HH:mm format.');
    }
  }

  private timestamp(value: unknown): string | null {
    if (!value) return null;
    if (typeof value === 'object' && value !== null && 'toDate' in value && typeof (value as {toDate?: unknown}).toDate === 'function') {
      return (value as {toDate: () => Date}).toDate().toISOString();
    }
    return value instanceof Date ? value.toISOString() : null;
  }
}
