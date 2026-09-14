import { Body, Controller, Get, Param, Patch, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AdminGuard } from '../auth/admin.guard';
import { SuperAdminGuard } from '../auth/super-admin.guard';
import { AuthenticatedRequest } from '../auth/auth.types';
import { AdminUsersService } from './admin-users.service';

@Controller('admin/users')
@UseGuards(AdminGuard)
export class AdminUsersController {
  constructor(private readonly service: AdminUsersService) {}

  @Get()
  @UseGuards(SuperAdminGuard)
  listUsers(
    @Query('search') search?: string,
    @Query('role') role?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.service.listUsers({
      search,
      role,
      page: page ? Number(page) : undefined,
      pageSize: pageSize ? Number(pageSize) : undefined,
    });
  }

  @Patch(':id/role')
  @UseGuards(SuperAdminGuard)
  changeRole(
    @Param('id') id: string,
    @Body() body: { role?: string },
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
