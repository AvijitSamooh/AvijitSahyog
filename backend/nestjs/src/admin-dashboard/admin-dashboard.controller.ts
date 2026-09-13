import { Controller, Get, UseGuards } from '@nestjs/common';
import { AdminGuard } from '../auth/admin.guard';
import { SuperAdminGuard } from '../auth/super-admin.guard';
import { AdminDashboardService } from './admin-dashboard.service';

@Controller('admin/dashboard')
@UseGuards(AdminGuard)
export class AdminDashboardController {
  constructor(private readonly dashboardService: AdminDashboardService) {}

  @Get()
  getSummary() {
    return this.dashboardService.getSummary();
  }

  @Get('analytics')
  @UseGuards(SuperAdminGuard)
  getAnalytics() {
    return this.dashboardService.getAnalytics();
  }

  @Get('analytics/advanced')
  @UseGuards(SuperAdminGuard)
  getAdvancedAnalytics() {
    return this.dashboardService.getAdvancedAnalytics();
  }
}
