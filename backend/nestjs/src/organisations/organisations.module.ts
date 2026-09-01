import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { AdminOrganisationsController } from './admin-organisations.controller';
import { OrganisationsController } from './organisations.controller';
import { OrganisationsService } from './organisations.service';

@Module({
  imports: [AuthModule],
  controllers: [OrganisationsController, AdminOrganisationsController],
  providers: [OrganisationsService],
})
export class OrganisationsModule {}
