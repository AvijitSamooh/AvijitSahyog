import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { PrismaModule } from '../prisma/prisma.module';
import { MediaModule } from '../media/media.module';
import { ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController, ApplicationRulesController, AdminApplicationRulesController, CertificatePhotoExportController } from './help-applications.controller';
import { HelpApplicationsService } from './help-applications.service';
import { ApplicationWindowsService } from './application-windows.service';
import { ApplicationRulesService } from './application-rules.service';
import { FirestoreApplicationRulesService } from './firestore-application-rules.service';
import { FirestoreApplicationWindowsService } from './firestore-application-windows.service';

@Module({
  imports: [AuthModule, PrismaModule, FirebaseModule, MediaModule],
  controllers: [ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController, ApplicationRulesController, AdminApplicationRulesController, CertificatePhotoExportController],
  providers: [ApplicationWindowsService, FirestoreApplicationWindowsService, ApplicationRulesService, FirestoreApplicationRulesService, HelpApplicationsService],
})
export class HelpApplicationsModule {}
