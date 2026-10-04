import { BadRequestException, Injectable } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirebaseIdentity } from '../auth/auth.types';
import { FirestoreUsersService } from '../users/firestore-users.service';
import { FirebaseService } from '../firebase/firebase.service';
import { HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { StartApplicationWindowDto } from './dto/application-window.dto';

const APPLICATION_TYPES = Object.values(HelpApplicationTypeDto);

type WindowDocument = {
  type: HelpApplicationTypeDto;
  startsAt: Timestamp;
  registrationEndsAt: Timestamp | null;
  eventAt: Timestamp | null;
  closedAt: Timestamp | null;
  updatedById: string;
  updatedAt: Timestamp;
};

@Injectable()
export class FirestoreApplicationWindowsService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly users: FirestoreUsersService,
  ) {}

  async list() {
    const now = new Date();
    const snapshot = await this.firebase.db.collection('applicationWindows').get();
    return {
      serverNow: now.toISOString(),
      windows: snapshot.docs
        .map((doc) => this.toDocument(doc.data()))
        .sort((a, b) => a.type.localeCompare(b.type))
        .map((window) => this.toResponse(window, now)),
    };
  }

  async start(identity: FirebaseIdentity, type: HelpApplicationTypeDto, dto: StartApplicationWindowDto) {
    const admin = await this.requireAdmin(identity);
    this.validateType(type);
    if (dto.type !== type) {
      throw new BadRequestException('Application type in the path and request body must match.');
    }

    const startsAt = dto.startsAt ? new Date(dto.startsAt) : new Date();
    const registrationEndsAt = dto.registrationEndsAt ? new Date(dto.registrationEndsAt) : null;
    const eventAt = dto.eventAt ? new Date(dto.eventAt) : null;
    this.validateDates(startsAt, registrationEndsAt, eventAt);

    const now = Timestamp.now();
    const document: WindowDocument = {
      type,
      startsAt: Timestamp.fromDate(startsAt),
      registrationEndsAt: registrationEndsAt ? Timestamp.fromDate(registrationEndsAt) : null,
      eventAt: eventAt ? Timestamp.fromDate(eventAt) : null,
      closedAt: null,
      updatedById: admin.id,
      updatedAt: now,
    };

    await this.firebase.db.collection('applicationWindows').doc(type).set(document);
    return this.toResponse(document, new Date());
  }

  async close(identity: FirebaseIdentity, type: HelpApplicationTypeDto) {
    const admin = await this.requireAdmin(identity);
    this.validateType(type);
    const ref = this.firebase.db.collection('applicationWindows').doc(type);
    const snapshot = await ref.get();
    if (!snapshot.exists) {
      throw new BadRequestException('This application window has not been configured yet.');
    }

    const now = new Date();
    const closedAt = Timestamp.fromDate(now);
    await ref.update({ closedAt, updatedById: admin.id, updatedAt: Timestamp.now() });
    return this.toResponse({ ...this.toDocument(snapshot.data()), closedAt, updatedById: admin.id }, now);
  }

  async ensureAccepting(type: string) {
    this.validateType(type);
    const snapshot = await this.firebase.db.collection('applicationWindows').doc(type).get();
    if (!snapshot.exists) {
      throw new BadRequestException('Applications are not currently being accepted.');
    }

    const window = this.toDocument(snapshot.data());
    const now = new Date();
    const response = this.toResponse(window, now);
    if (response.status !== 'OPEN') {
      if (window.startsAt.toDate() > now) {
        throw new BadRequestException(`Applications will start from ${window.startsAt.toDate().toISOString()}.`);
      }
      if (window.registrationEndsAt && window.registrationEndsAt.toDate() <= now) {
        throw new BadRequestException('The registration deadline has passed.');
      }
      throw new BadRequestException('Applications are no longer being accepted.');
    }
    return response;
  }

  private toDocument(data: FirebaseFirestore.DocumentData | undefined): WindowDocument {
    return {
      type: data?.type as HelpApplicationTypeDto,
      startsAt: this.timestamp(data?.startsAt),
      registrationEndsAt: data?.registrationEndsAt ? this.timestamp(data.registrationEndsAt) : null,
      eventAt: data?.eventAt ? this.timestamp(data.eventAt) : null,
      closedAt: data?.closedAt ? this.timestamp(data.closedAt) : null,
      updatedById: String(data?.updatedById ?? ''),
      updatedAt: this.timestamp(data?.updatedAt ?? Timestamp.now()),
    };
  }

  private timestamp(value: unknown): Timestamp {
    if (value instanceof Timestamp) return value;
    if (value instanceof Date) return Timestamp.fromDate(value);
    return Timestamp.fromDate(new Date(String(value)));
  }

  private toResponse(window: WindowDocument, now: Date) {
    let status: 'SCHEDULED' | 'OPEN' | 'CLOSED';
    if (window.startsAt.toDate() > now) {
      status = 'SCHEDULED';
    } else if (
      (window.registrationEndsAt && window.registrationEndsAt.toDate() <= now) ||
      (window.closedAt && window.closedAt.toDate() <= now)
    ) {
      status = 'CLOSED';
    } else {
      status = 'OPEN';
    }

    return {
      type: window.type,
      startsAt: window.startsAt.toDate(),
      registrationEndsAt: window.registrationEndsAt?.toDate() ?? null,
      eventAt: window.eventAt?.toDate() ?? null,
      closedAt: window.closedAt?.toDate() ?? null,
      status,
      canApply: status === 'OPEN',
    };
  }

  private validateDates(
    startsAt: Date,
    registrationEndsAt: Date | null,
    eventAt: Date | null,
  ) {
    if (
      Number.isNaN(startsAt.getTime()) ||
      (registrationEndsAt && Number.isNaN(registrationEndsAt.getTime())) ||
      (eventAt && Number.isNaN(eventAt.getTime()))
    ) {
      throw new BadRequestException('Application schedule contains an invalid date.');
    }
    if (registrationEndsAt && registrationEndsAt < startsAt) {
      throw new BadRequestException('Registration end cannot be before the form availability date.');
    }
    const eventMinimum = registrationEndsAt ?? startsAt;
    if (eventAt && eventAt < eventMinimum) {
      throw new BadRequestException('Event date cannot be before the registration end date or form availability date.');
    }
  }

  private validateType(type: string): asserts type is HelpApplicationTypeDto {
    if (!APPLICATION_TYPES.includes(type as HelpApplicationTypeDto)) {
      throw new BadRequestException('Unsupported application type.');
    }
  }

  private async requireAdmin(identity: FirebaseIdentity) {
    const user = await this.users.getByFirebaseUid(identity.uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'SUPER_ADMIN')) {
      throw new BadRequestException('Administrator access is required.');
    }
    return user;
  }
}
