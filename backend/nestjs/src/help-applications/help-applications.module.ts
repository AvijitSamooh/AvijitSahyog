import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController } from './help-applications.controller';
import { HelpApplicationsService } from './help-applications.service';
import { ApplicationWindowsService } from './application-windows.service';

@Module({
  imports: [AuthModule],
  controllers: [ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController],
  providers: [ApplicationWindowsService, HelpApplicationsService],
})
export class HelpApplicationsModule {}
