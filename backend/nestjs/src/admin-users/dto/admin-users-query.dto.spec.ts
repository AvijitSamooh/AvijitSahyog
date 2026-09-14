import { BadRequestException } from '@nestjs/common';
import { AdminUsersQueryDto } from './admin-users-query.dto';

describe('AdminUsersQueryDto', () => {
  it('uses safe defaults for an empty query', () => {
    expect(AdminUsersQueryDto.fromQuery({})).toEqual(
      expect.objectContaining({ role: 'ADMIN', page: 1, pageSize: 3 }),
    );
  });

  it('trims search and parses valid pagination values', () => {
    expect(AdminUsersQueryDto.fromQuery({
      search: '  nikita  ',
      role: 'USER',
      page: '2',
      pageSize: '10',
    })).toEqual(expect.objectContaining({
      search: 'nikita',
      role: 'USER',
      page: 2,
      pageSize: 10,
    }));
  });

  it.each([
    ['role', { role: 'SUPER_ADMIN' }],
    ['page', { page: '0' }],
    ['pageSize', { pageSize: '21' }],
    ['pageSize type', { pageSize: 3 }],
  ])('rejects invalid %s', (_, query) => {
    expect(() => AdminUsersQueryDto.fromQuery(query)).toThrow(BadRequestException);
  });
});
