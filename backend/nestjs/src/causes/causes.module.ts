import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { AdminCausesController } from './admin-causes.controller';
import { CausesController } from './causes.controller';
import { CausesService } from './causes.service';

@Module({
  imports: [AuthModule],
  controllers: [CausesController, AdminCausesController],
  providers: [CausesService],
})
export class CausesModule {}
