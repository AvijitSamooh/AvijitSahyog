import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { FirebaseTokenVerifierService } from './firebase-token-verifier.service';
import { AdminGuard } from './admin.guard';
import { SuperAdminGuard } from './super-admin.guard';
import { FirebaseModule } from '../firebase/firebase.module';
import { FirestoreUsersService } from '../users/firestore-users.service';

@Module({
  imports: [FirebaseModule],
  controllers: [AuthController],
  providers: [
    AuthService,
    FirestoreUsersService,
    FirebaseAuthGuard,
    FirebaseTokenVerifierService,
    AdminGuard,
    SuperAdminGuard,
  ],
  exports: [
    AuthService,
    FirestoreUsersService,
    FirebaseAuthGuard,
    FirebaseTokenVerifierService,
    AdminGuard,
    SuperAdminGuard,
  ],
})
export class AuthModule {}
