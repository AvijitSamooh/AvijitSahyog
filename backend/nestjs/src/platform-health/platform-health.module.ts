import { Module } from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { PlatformHealthController } from './platform-health.controller';
import { PlatformHealthExceptionFilter } from './platform-health.exception-filter';
import { PlatformHealthService } from './platform-health.service';
import { PlatformDowntimeController } from './platform-downtime.controller';
import { PlatformDowntimeService } from './platform-downtime.service';
import { PlatformDowntimeGuard } from './platform-downtime.guard';
import { FirestorePlatformHealthService } from './firestore-platform-health.service';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [PlatformHealthController, PlatformDowntimeController],
  providers: [
    PlatformHealthService,
    PlatformDowntimeService,
    FirestorePlatformHealthService,
    {
      provide: APP_GUARD,
      useClass: PlatformDowntimeGuard,
    },
    {
      provide: APP_FILTER,
      useFactory: (health: PlatformHealthService) => new PlatformHealthExceptionFilter(health),
      inject: [PlatformHealthService],
    },
  ],
  exports: [PlatformHealthService],
})
export class PlatformHealthModule {}
