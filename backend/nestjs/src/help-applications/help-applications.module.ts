import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { HelpApplicationsController, AdminHelpApplicationsController } from './help-applications.controller';
import { HelpApplicationsService } from './help-applications.service';

@Module({
  imports: [AuthModule],
  controllers: [HelpApplicationsController, AdminHelpApplicationsController],
  providers: [HelpApplicationsService],
})
export class HelpApplicationsModule {}
