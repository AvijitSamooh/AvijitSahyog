import { IsIn } from 'class-validator';

export class ChangeAdminUserRoleDto {
  @IsIn(['USER', 'ADMIN'])
  role!: 'USER' | 'ADMIN';
}
