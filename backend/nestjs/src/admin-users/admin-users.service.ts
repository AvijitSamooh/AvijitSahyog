import { Injectable } from '@nestjs/common';
import { FirestoreUsersService, UserListQuery } from '../users/firestore-users.service';

@Injectable()
export class AdminUsersService {
  constructor(private readonly users: FirestoreUsersService) {}

  listUsers(query: UserListQuery = {}) {
    return this.users.listUsers(query);
  }

  changeRole(targetUserId: string, actorFirebaseUid: string, requestedRole?: string) {
    return this.users.changeRole(targetUserId, actorFirebaseUid, requestedRole);
  }

  getAuditHistory() {
    return this.users.getAuditHistory();
  }
}
