import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ChangeAdminUserRoleDto } from './change-admin-user-role.dto';

describe('ChangeAdminUserRoleDto', () => {
  it.each(['USER', 'ADMIN'])('accepts %s', async (role) => {
    const dto = plainToInstance(ChangeAdminUserRoleDto, { role });
    expect(await validate(dto)).toHaveLength(0);
  });

  it('rejects unsupported roles', async () => {
    const dto = plainToInstance(ChangeAdminUserRoleDto, { role: 'SUPER_ADMIN' });
    expect(await validate(dto)).not.toHaveLength(0);
  });
});
