import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type ManagedRole = 'USER' | 'ADMIN';
type ListUsersQuery = {
  search?: string;
  role?: string;
  page?: number;
  pageSize?: number;
};

@Injectable()
export class AdminUsersService {
  constructor(private readonly prisma: PrismaService) {}

  async listUsers(query: ListUsersQuery = {}) {
    const page = Number.isFinite(query.page) && (query.page ?? 0) > 0 ? Math.floor(query.page!) : 1;
    const pageSize = Number.isFinite(query.pageSize) && (query.pageSize ?? 0) > 0
      ? Math.min(Math.floor(query.pageSize!), 20)
      : 3;
    const search = query.search?.trim();
    const role: UserRole = query.role === 'USER' ? UserRole.USER : UserRole.ADMIN;

    const where = {
      role,
      ...(search
        ? {
            OR: [
              { displayName: { contains: search, mode: 'insensitive' as const } },
              { email: { contains: search, mode: 'insensitive' as const } },
            ],
          }
        : {}),
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.user.count({ where }),
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
        select: {
          id: true,
          email: true,
          displayName: true,
          photoUrl: true,
          role: true,
          createdAt: true,
        },
      }),
    ]);

    return {
      items,
      page,
      pageSize,
      total,
    };
  }

  async changeRole(targetUserId: string, actorFirebaseUid: string, requestedRole?: string) {
    if (requestedRole !== 'USER' && requestedRole !== 'ADMIN') {
      throw new BadRequestException('Role must be USER or ADMIN.');
    }

    const actor = await this.prisma.user.findUnique({
      where: { firebaseUid: actorFirebaseUid },
      select: { id: true, role: true },
    });
    if (!actor) {
      throw new NotFoundException('Administrator account was not found.');
    }
    if (actor.role !== 'SUPER_ADMIN') {
      throw new BadRequestException('Only a Super Admin can change administrator roles.');
    }

    const target = await this.prisma.user.findUnique({
      where: { id: targetUserId },
      select: { id: true, role: true },
    });
    if (!target) {
      throw new NotFoundException('User was not found.');
    }
    if (target.id === actor.id) {
      throw new BadRequestException('A Super Admin cannot change their own role.');
    }
    if (target.role === 'SUPER_ADMIN') {
      throw new BadRequestException('Super Admin roles cannot be changed from this screen.');
    }
    if (target.role === requestedRole) {
      throw new ConflictException(
        `User is already ${requestedRole === 'ADMIN' ? 'an administrator' : 'a regular user'}.`,
      );
    }

    const fromRole = target.role as ManagedRole;
    const toRole = requestedRole as ManagedRole;
    const reason = toRole === 'ADMIN' ? 'admin_promotion' : 'admin_demotion';

    return this.prisma.$transaction(async (tx) => {
      const updatedUser = await tx.user.update({
        where: { id: target.id },
        data: { role: toRole },
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
          fromRole,
          toRole,
          metadata: { reason },
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
        metadata: true,
        createdAt: true,
        actor: { select: { id: true, displayName: true, email: true } },
        targetUser: { select: { id: true, displayName: true, email: true } },
      },
    });
  }
}
