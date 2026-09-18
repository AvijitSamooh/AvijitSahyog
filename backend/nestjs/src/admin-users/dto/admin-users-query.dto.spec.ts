import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AdminUsersQueryDto } from './admin-users-query.dto';

describe('AdminUsersQueryDto', () => {
  it('uses safe defaults for an empty query', async () => {
    const dto = plainToInstance(AdminUsersQueryDto, {});
    expect(dto.role).toBe('ADMIN');
    expect(dto.page).toBe(1);
    expect(dto.pageSize).toBe(3);
    expect(await validate(dto)).toHaveLength(0);
  });

  it('trims search and transforms pagination values', async () => {
    const dto = plainToInstance(AdminUsersQueryDto, {
      search: '  nikita  ',
      role: 'USER',
      page: '2',
      pageSize: '10',
    });

    expect(dto.search).toBe('nikita');
    expect(dto.role).toBe('USER');
    expect(dto.page).toBe(2);
    expect(dto.pageSize).toBe(10);
    expect(await validate(dto)).toHaveLength(0);
  });

  it('accepts ALL for cross-role search', async () => {
    const dto = plainToInstance(AdminUsersQueryDto, { role: 'ALL' });
    expect(dto.role).toBe('ALL');
    expect(await validate(dto)).toHaveLength(0);
  });

  it('rejects invalid query values', async () => {
    const dto = plainToInstance(AdminUsersQueryDto, {
      role: 'SUPER_ADMIN',
      page: '0',
      pageSize: '21',
    });

    expect((await validate(dto)).length).toBeGreaterThan(0);
  });
});
