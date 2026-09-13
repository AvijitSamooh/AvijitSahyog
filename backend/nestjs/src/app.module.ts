import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CausesModule } from './causes/causes.module';
import { DonationsModule } from './donations/donations.module';
import { OrganisationsModule } from './organisations/organisations.module';
import { PrismaModule } from './prisma/prisma.module';
import { BeneficiariesModule } from './beneficiaries/beneficiaries.module';
import { AuthModule } from './auth/auth.module';
import { AdminDashboardModule } from './admin-dashboard/admin-dashboard.module';
import { MediaModule } from './media/media.module';
import { AdminUsersModule } from './admin-users/admin-users.module';
import { AnalyticsModule } from './analytics/analytics.module';

@Module({
  imports: [PrismaModule, AuthModule, AnalyticsModule, CausesModule, OrganisationsModule, DonationsModule, BeneficiariesModule, AdminDashboardModule, MediaModule, AdminUsersModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
