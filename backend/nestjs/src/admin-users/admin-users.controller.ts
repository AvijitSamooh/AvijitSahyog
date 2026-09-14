import { BadRequestException, Body, Controller, Get, Param, Patch, Req, UseGuards } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import type { Request } from 'express';
import { AdminGuard } from '../auth/admin.guard';
import { SuperAdminGuard } from '../auth/super-admin.guard';
import type { AuthenticatedRequest } from '../auth/auth.types';
import { AdminUsersQueryDto } from './dto/admin-users-query.dto';
import { ChangeAdminUserRoleDto } from './dto/change-admin-user-role.dto';
import { AdminUsersService } from './admin-users.service';

@Controller('admin/users')
@UseGuards(AdminGuard)
export class AdminUsersController {
  constructor(private readonly service: AdminUsersService) {}

  @Get()
  @UseGuards(SuperAdminGuard)
  async listUsers(@Req() request: Request) {
    const dto = plainToInstance(AdminUsersQueryDto, request.query);
    const errors = await validate(dto, { whitelist: true, forbidNonWhitelisted: true });
    if (errors.length) {
      throw new BadRequestException('Invalid admin user query.');
    }
    return this.service.listUsers(dto);
  }

  @Patch(':id/role')
  @UseGuards(SuperAdminGuard)
  async changeRole(
    @Param('id') id: string,
    @Body() body: ChangeAdminUserRoleDto,
    @Req() request: Request & AuthenticatedRequest,
  ) {
    const dto = plainToInstance(ChangeAdminUserRoleDto, body);
    const errors = await validate(dto, { whitelist: true, forbidNonWhitelisted: true });
    if (errors.length) {
      throw new BadRequestException('Invalid administrator role.');
    }
    return this.service.changeRole(id, request.user.uid, dto.role);
  }

  @Get('audit-history')
  @UseGuards(SuperAdminGuard)
  getAuditHistory() {
    return this.service.getAuditHistory();
  }
}
