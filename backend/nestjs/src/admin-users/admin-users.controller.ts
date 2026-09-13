import { Body, Controller, Get, Param, Patch, Req, UseGuards } from '@nestjs/common';
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
  listUsers() {
    return this.service.listUsers();
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
