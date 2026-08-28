import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CausesModule } from './causes/causes.module';
import { OrganisationsModule } from './organisations/organisations.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [PrismaModule, CausesModule, OrganisationsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
