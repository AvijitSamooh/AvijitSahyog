import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminUsersService {
  constructor(private readonly prisma: PrismaService) {}

  async listUsers() {
    return this.prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        displayName: true,
        photoUrl: true,
        role: true,
        createdAt: true,
      },
    });
  }

  async changeRoleToAdmin(targetUserId: string, actorFirebaseUid: string, requestedRole?: string) {
    if (requestedRole && requestedRole !== 'ADMIN') {
      throw new BadRequestException('Only promotion to ADMIN is supported.');
    }

    const actor = await this.prisma.user.findUnique({
      where: { firebaseUid: actorFirebaseUid },
      select: { id: true },
    });
    if (!actor) {
      throw new NotFoundException('Administrator account was not found.');
    }

    const target = await this.prisma.user.findUnique({
      where: { id: targetUserId },
      select: { id: true, role: true },
    });
    if (!target) {
      throw new NotFoundException('User was not found.');
    }
    if (target.id === actor.id) {
      throw new BadRequestException('An administrator cannot change their own role.');
    }
    if (target.role === 'ADMIN') {
      throw new ConflictException('User is already an administrator.');
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedUser = await tx.user.update({
        where: { id: target.id },
        data: { role: 'ADMIN' },
        select: {
          id: true,
          email: true,
          displayName: true,
          photoUrl: true,
          role: true,
          createdAt: true,
        },
      });

      await tx.auditLog.create({
        data: {
          action: 'USER_ROLE_CHANGED',
          actorUserId: actor.id,
          targetUserId: target.id,
          fromRole: target.role,
          toRole: 'ADMIN',
          metadata: { reason: 'admin_promotion' },
        },
      });

      return updatedUser;
    });
  }

  async getAuditHistory() {
    return this.prisma.auditLog.findMany({
      where: { action: 'USER_ROLE_CHANGED' },
      orderBy: { createdAt: 'desc' },
      take: 100,
      select: {
        id: true,
        action: true,
        fromRole: true,
        toRole: true,
        createdAt: true,
        actor: { select: { id: true, displayName: true, email: true } },
        targetUser: { select: { id: true, displayName: true, email: true } },
      },
    });
  }
}
