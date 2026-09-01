import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { FirebaseTokenVerifierService } from './firebase-token-verifier.service';
import { AdminGuard } from './admin.guard';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AuthController],
  providers: [AuthService, FirebaseAuthGuard, FirebaseTokenVerifierService, AdminGuard],
  exports: [FirebaseAuthGuard, AdminGuard],
})
export class AuthModule {}
