import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { MediaModule } from '../media/media.module';
import { ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController, ApplicationRulesController, AdminApplicationRulesController, CertificatePhotoExportController } from './help-applications.controller';
import { HelpApplicationsService } from './help-applications.service';
import { ApplicationWindowsService } from './application-windows.service';
import { ApplicationRulesService } from './application-rules.service';

@Module({
  imports: [AuthModule, PrismaModule, MediaModule],
  controllers: [ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController, ApplicationRulesController, AdminApplicationRulesController, CertificatePhotoExportController],
  providers: [ApplicationWindowsService, ApplicationRulesService, HelpApplicationsService],
})
export class HelpApplicationsModule {}
