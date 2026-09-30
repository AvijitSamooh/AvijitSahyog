import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController, ApplicationRulesController, AdminApplicationRulesController } from './help-applications.controller';
import { HelpApplicationsService } from './help-applications.service';
import { ApplicationWindowsService } from './application-windows.service';
import { ApplicationRulesService } from './application-rules.service';

@Module({
  imports: [AuthModule],
  controllers: [ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController, ApplicationRulesController, AdminApplicationRulesController],
  providers: [ApplicationWindowsService, ApplicationRulesService, HelpApplicationsService],
})
export class HelpApplicationsModule {}
