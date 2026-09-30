import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseIdentity } from '../auth/auth.types';
import { HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { StartApplicationWindowDto } from './dto/application-window.dto';

const APPLICATION_TYPES = Object.values(HelpApplicationTypeDto);

@Injectable()
export class ApplicationWindowsService {
  constructor(private readonly prisma: PrismaService) {}

  async list() {
    const now = new Date();
    const windows = await this.prisma.applicationWindow.findMany({
      orderBy: { type: 'asc' },
    });
    return {
      serverNow: now.toISOString(),
      windows: windows.map((window) => this.toResponse(window, now)),
    };
  }

  async start(identity: FirebaseIdentity, type: HelpApplicationTypeDto, dto: StartApplicationWindowDto) {
    const admin = await this.requireAdmin(identity);
    this.validateType(type);
    if (dto.type !== type) {
      throw new BadRequestException('Application type in the path and request body must match.');
    }
    const startsAt = dto.startsAt ? new Date(dto.startsAt) : new Date();
    if (Number.isNaN(startsAt.getTime())) {
      throw new BadRequestException('Application start date is invalid.');
    }

    const now = new Date();
    const item = await this.prisma.applicationWindow.upsert({
      where: { type },
      create: {
        type,
        startsAt,
        closedAt: null,
        updatedById: admin.id,
      },
      update: {
        startsAt,
        closedAt: null,
        updatedById: admin.id,
      },
    });
    return this.toResponse(item, now);
  }

  async close(identity: FirebaseIdentity, type: HelpApplicationTypeDto) {
    const admin = await this.requireAdmin(identity);
    this.validateType(type);
    const existing = await this.prisma.applicationWindow.findUnique({ where: { type } });
    if (!existing) {
      throw new BadRequestException('This application window has not been configured yet.');
    }

    const now = new Date();
    const item = await this.prisma.applicationWindow.update({
      where: { type },
      data: { closedAt: now, updatedById: admin.id },
    });
    return this.toResponse(item, now);
  }

  async ensureAccepting(type: string) {
    this.validateType(type);
    const now = new Date();
    const window = await this.prisma.applicationWindow.findUnique({ where: { type } });
    if (!window) {
      throw new BadRequestException('Applications are not currently being accepted.');
    }
    if (window.startsAt > now) {
      throw new BadRequestException(`Applications will start from ${window.startsAt.toISOString()}.`);
    }
    if (window.closedAt && window.closedAt <= now) {
      throw new BadRequestException('Applications are no longer being accepted.');
    }
    return window;
  }

  private toResponse(window: any, now: Date) {
    let status: 'SCHEDULED' | 'OPEN' | 'CLOSED';
    if (window.startsAt > now) {
      status = 'SCHEDULED';
    } else if (window.closedAt && window.closedAt <= now) {
      status = 'CLOSED';
    } else {
      status = 'OPEN';
    }

    return {
      type: window.type,
      startsAt: window.startsAt,
      closedAt: window.closedAt,
      status,
      canApply: status === 'OPEN',
    };
  }

  private validateType(type: string): asserts type is HelpApplicationTypeDto {
    if (!APPLICATION_TYPES.includes(type as HelpApplicationTypeDto)) {
      throw new BadRequestException('Unsupported application type.');
    }
  }

  private async user(identity: FirebaseIdentity) {
    return this.prisma.user.upsert({
      where: { firebaseUid: identity.uid },
      create: { firebaseUid: identity.uid, email: identity.email, displayName: identity.displayName, photoUrl: identity.photoUrl },
      update: { email: identity.email, displayName: identity.displayName, photoUrl: identity.photoUrl },
    });
  }

  private async requireAdmin(identity: FirebaseIdentity) {
    const user = await this.user(identity);
    if (user.role !== 'ADMIN' && user.role !== 'SUPER_ADMIN') {
      throw new BadRequestException('Administrator access is required.');
    }
    return user;
  }
}
