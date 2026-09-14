import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
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
  listUsers(@Query() query: AdminUsersQueryDto) {
    return this.service.listUsers(query);
  }

  @Patch(':id/role')
  @UseGuards(SuperAdminGuard)
  changeRole(
    @Param('id') id: string,
    @Body() body: ChangeAdminUserRoleDto,
    @Req() request: Request & AuthenticatedRequest,
  ) {
    return this.service.changeRole(id, request.user.uid, body.role);
  }

  @Get('audit-history')
  @UseGuards(SuperAdminGuard)
  getAuditHistory() {
    return this.service.getAuditHistory();
  }
}
