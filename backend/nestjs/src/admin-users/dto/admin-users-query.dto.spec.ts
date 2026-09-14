import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AdminUsersQueryDto } from './admin-users-query.dto';

describe('AdminUsersQueryDto', () => {
  it('uses safe defaults for an empty query', async () => {
    const dto = plainToInstance(AdminUsersQueryDto, {});
    expect(await validate(dto)).toHaveLength(0);
    expect(dto).toEqual(expect.objectContaining({ role: 'ADMIN', page: 1, pageSize: 3 }));
  });

  it('trims search and transforms valid pagination values', async () => {
    const dto = plainToInstance(AdminUsersQueryDto, {
      search: '  nikita  ',
      role: 'USER',
      page: '2',
      pageSize: '10',
    });
    expect(await validate(dto)).toHaveLength(0);
    expect(dto).toEqual(expect.objectContaining({
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
    ['pageSize type', { pageSize: [] }],
  ])('rejects invalid %s', async (_, query) => {
    const dto = plainToInstance(AdminUsersQueryDto, query);
    expect(await validate(dto)).not.toHaveLength(0);
  });
});
