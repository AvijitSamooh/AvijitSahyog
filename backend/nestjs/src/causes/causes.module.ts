import { Module } from '@nestjs/common';
import { CausesController } from './causes.controller';
import { CausesService } from './causes.service';

@Module({
  controllers: [CausesController],
  providers: [CausesService],
})
export class CausesModule {}
