import { BadRequestException } from '@nestjs/common';

const DEFAULT_PAGE = 1;
const DEFAULT_PAGE_SIZE = 3;
const MAX_PAGE_SIZE = 20;
const ALLOWED_ROLES = new Set(['USER', 'ADMIN']);

export class AdminUsersQueryDto {
  readonly search?: string;
  readonly role: 'USER' | 'ADMIN';
  readonly page: number;
  readonly pageSize: number;

  private constructor(values: {
    search?: string;
    role: 'USER' | 'ADMIN';
    page: number;
    pageSize: number;
  }) {
    this.search = values.search;
    this.role = values.role;
    this.page = values.page;
    this.pageSize = values.pageSize;
  }

  static fromQuery(query: Record<string, unknown>): AdminUsersQueryDto {
    const search = typeof query.search === 'string' ? query.search.trim() : undefined;
    if (query.search !== undefined && typeof query.search !== 'string') {
      throw new BadRequestException('search must be a string.');
    }

    const role = query.role === undefined ? 'ADMIN' : query.role;
    if (typeof role !== 'string' || !ALLOWED_ROLES.has(role)) {
      throw new BadRequestException('role must be USER or ADMIN.');
    }

    const page = AdminUsersQueryDto.parsePositiveInteger(query.page, 'page', DEFAULT_PAGE);
    const pageSize = AdminUsersQueryDto.parsePositiveInteger(
      query.pageSize,
      'pageSize',
      DEFAULT_PAGE_SIZE,
    );
    if (pageSize > MAX_PAGE_SIZE) {
      throw new BadRequestException(`pageSize must be between 1 and ${MAX_PAGE_SIZE}.`);
    }

    return new AdminUsersQueryDto({
      search: search || undefined,
      role: role as 'USER' | 'ADMIN',
      page,
      pageSize,
    });
  }

  private static parsePositiveInteger(value: unknown, name: string, fallback: number): number {
    if (value === undefined) return fallback;
    if (typeof value !== 'string' || !/^\d+$/.test(value)) {
      throw new BadRequestException(`${name} must be a positive integer.`);
    }
    const parsed = Number(value);
    if (!Number.isSafeInteger(parsed) || parsed < 1) {
      throw new BadRequestException(`${name} must be a positive integer.`);
    }
    return parsed;
  }
}
