import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { MediaModule } from '../media/media.module';
import { ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController, ApplicationRulesController, AdminApplicationRulesController, CertificatePhotoExportController } from './help-applications.controller';
import { HelpApplicationsService } from './help-applications.service';
import { ApplicationWindowsService } from './application-windows.service';
import { ApplicationRulesService } from './application-rules.service';
import { FirestoreApplicationRulesService } from './firestore-application-rules.service';
import { FirestoreApplicationWindowsService } from './firestore-application-windows.service';
import { FirestoreHelpApplicationsService } from './firestore-help-applications.service';

@Module({
  imports: [AuthModule, FirebaseModule, MediaModule],
  controllers: [ApplicationWindowsController, AdminApplicationWindowsController, HelpApplicationsController, AdminHelpApplicationsController, ApplicationRulesController, AdminApplicationRulesController, CertificatePhotoExportController],
  providers: [
    FirestoreApplicationWindowsService,
    FirestoreApplicationRulesService,
    FirestoreHelpApplicationsService,
    { provide: ApplicationWindowsService, useExisting: FirestoreApplicationWindowsService },
    { provide: ApplicationRulesService, useExisting: FirestoreApplicationRulesService },
    { provide: HelpApplicationsService, useExisting: FirestoreHelpApplicationsService },
  ],
})
export class HelpApplicationsModule {}
