import { Body, Controller, Get, Param, Patch, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AdminGuard } from '../auth/admin.guard';
import { AuthenticatedRequest } from '../auth/auth.types';
import { AdminUsersService } from './admin-users.service';

@Controller('admin/users')
@UseGuards(AdminGuard)
export class AdminUsersController {
  constructor(private readonly service: AdminUsersService) {}

  @Get()
  listUsers() {
    return this.service.listUsers();
  }

  @Patch(':id/role')
  makeAdmin(
    @Param('id') id: string,
    @Body() body: { role?: string },
    @Req() request: Request & AuthenticatedRequest,
  ) {
    return this.service.changeRoleToAdmin(id, request.user.uid, body.role);
  }

  @Get('audit-history')
  getAuditHistory() {
    return this.service.getAuditHistory();
  }
}
