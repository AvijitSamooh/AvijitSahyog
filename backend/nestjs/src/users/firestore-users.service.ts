import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Timestamp, type DocumentSnapshot, type Query } from 'firebase-admin/firestore';
import { randomUUID } from 'node:crypto';
import { FirebaseService } from '../firebase/firebase.service';
import { FirebaseIdentity } from '../auth/auth.types';

export type UserRole = 'USER' | 'ADMIN' | 'SUPER_ADMIN';

export interface FirestoreUser {
  id: string;
  firebaseUid: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  role: UserRole;
  preferredLanguage: string | null;
  createdAt: Date;
  updatedAt: Date;
  searchTokens: string[];
}

export interface UserListQuery {
  search?: string;
  role?: 'USER' | 'ADMIN' | 'ALL';
  page?: number;
  pageSize?: number;
}

interface AuditRecord {
  id: string;
  action: string;
  actorUserId: string;
  targetUserId: string | null;
  fromRole: UserRole | null;
  toRole: UserRole | null;
  metadata: Record<string, unknown> | null;
  createdAt: Date;
}

const USERS_COLLECTION = 'users';
const AUDIT_COLLECTION = 'auditLogs';
const MAX_SEARCH_PREFIX_LENGTH = 32;

function searchTokensFor(values: Array<string | null | undefined>): string[] {
  const tokens = new Set<string>();

  for (const value of values) {
    const normalized = value?.trim().toLowerCase();
    if (!normalized) continue;

    for (const word of normalized.split(/[^\p{L}\p{N}]+/u).filter(Boolean)) {
      const max = Math.min(word.length, MAX_SEARCH_PREFIX_LENGTH);
      for (let length = 1; length <= max; length += 1) {
        tokens.add(word.slice(0, length));
      }
    }
  }

  return [...tokens];
}

function toDate(value: unknown): Date {
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  return new Date(String(value));
}

function fromSnapshot(snapshot: DocumentSnapshot): FirestoreUser {
  const data = snapshot.data() as Omit<FirestoreUser, 'id' | 'createdAt' | 'updatedAt'> & {
    createdAt: FirebaseFirestore.Timestamp | Date;
    updatedAt: FirebaseFirestore.Timestamp | Date;
  };

  return {
    id: snapshot.id,
    ...data,
    createdAt: toDate(data.createdAt),
    updatedAt: toDate(data.updatedAt),
  };
}

@Injectable()
export class FirestoreUsersService {
  constructor(private readonly firebase: FirebaseService) {}

  async getByFirebaseUid(firebaseUid: string): Promise<FirestoreUser | null> {
    const snapshot = await this.firebase.db
      .collection(USERS_COLLECTION)
      .where('firebaseUid', '==', firebaseUid)
      .limit(1)
      .get();

    return snapshot.empty ? null : fromSnapshot(snapshot.docs[0]);
  }

  async getById(id: string): Promise<FirestoreUser | null> {
    const snapshot = await this.firebase.db.collection(USERS_COLLECTION).doc(id).get();
    return snapshot.exists ? fromSnapshot(snapshot) : null;
  }

  async upsertFromIdentity(identity: FirebaseIdentity): Promise<FirestoreUser> {
    return this.firebase.db.runTransaction(async (transaction) => {
      const existingSnapshot = await transaction.get(
        this.firebase.db
          .collection(USERS_COLLECTION)
          .where('firebaseUid', '==', identity.uid)
          .limit(1),
      );

      const now = Timestamp.now();
      if (!existingSnapshot.empty) {
        const existing = fromSnapshot(existingSnapshot.docs[0]);
        const update = {
          email: identity.email ?? null,
          displayName: identity.displayName ?? null,
          photoUrl: identity.photoUrl ?? null,
          searchTokens: searchTokensFor([identity.displayName, identity.email]),
          updatedAt: now,
        };
        transaction.update(existingSnapshot.docs[0].ref, update);
        return { ...existing, ...update, updatedAt: now.toDate() };
      }

      const id = randomUUID();
      const user = {
        id,
        firebaseUid: identity.uid,
        email: identity.email ?? null,
        displayName: identity.displayName ?? null,
        photoUrl: identity.photoUrl ?? null,
        role: 'USER' as const,
        preferredLanguage: null,
        createdAt: now,
        updatedAt: now,
        searchTokens: searchTokensFor([identity.displayName, identity.email]),
      };
      transaction.set(this.firebase.db.collection(USERS_COLLECTION).doc(id), user);
      return { ...user, createdAt: now.toDate(), updatedAt: now.toDate() };
    });
  }

  async listUsers(query: UserListQuery = {}) {
    const page = Number.isFinite(query.page) && (query.page ?? 0) > 0 ? Math.floor(query.page!) : 1;
    const pageSize =
      Number.isFinite(query.pageSize) && (query.pageSize ?? 0) > 0
        ? Math.min(Math.floor(query.pageSize!), 20)
        : 3;

    const search = query.search?.trim().toLowerCase();
    const role = query.role === 'USER' || query.role === 'ADMIN' ? query.role : undefined;

    let base: Query = this.firebase.db.collection(USERS_COLLECTION);
    if (role) base = base.where('role', '==', role);

    if (search) {
      const tokens = searchTokensFor([search]).slice(0, 30);
      if (!tokens.length) return { items: [], page, pageSize, total: 0 };
      base = base.where('searchTokens', 'array-contains-any', tokens);
    }

    const [countSnapshot, itemSnapshot] = await Promise.all([
      base.count().get(),
      base.orderBy('createdAt', 'desc').offset((page - 1) * pageSize).limit(pageSize).get(),
    ]);

    return {
      items: itemSnapshot.docs.map(fromSnapshot).map(({ searchTokens, ...user }) => user),
      page,
      pageSize,
      total: countSnapshot.data().count,
    };
  }

  async changeRole(targetUserId: string, actorFirebaseUid: string, requestedRole?: string) {
    if (requestedRole !== 'USER' && requestedRole !== 'ADMIN') {
      throw new BadRequestException('Role must be USER or ADMIN.');
    }

    const actor = await this.getByFirebaseUid(actorFirebaseUid);
    if (!actor) throw new NotFoundException('Administrator account was not found.');
    if (actor.role !== 'SUPER_ADMIN') {
      throw new BadRequestException('Only a Super Admin can change administrator roles.');
    }

    return this.firebase.db.runTransaction(async (transaction) => {
      const targetRef = this.firebase.db.collection(USERS_COLLECTION).doc(targetUserId);
      const targetSnapshot = await transaction.get(targetRef);

      if (!targetSnapshot.exists) throw new NotFoundException('User was not found.');
      const target = fromSnapshot(targetSnapshot);

      if (target.id === actor.id) {
        throw new BadRequestException('A Super Admin cannot change their own role.');
      }
      if (target.role === 'SUPER_ADMIN') {
        throw new BadRequestException('Super Admin roles cannot be changed from this screen.');
      }
      if (target.role === requestedRole) {
        throw new ConflictException(
          `User is already ${requestedRole === 'ADMIN' ? 'an administrator' : 'a regular user'}.`,
        );
      }

      const now = Timestamp.now();
      const reason = requestedRole === 'ADMIN' ? 'admin_promotion' : 'admin_demotion';
      transaction.update(targetRef, { role: requestedRole, updatedAt: now });
      const auditRef = this.firebase.db.collection(AUDIT_COLLECTION).doc(randomUUID());
      transaction.set(auditRef, {
        id: auditRef.id,
        action: 'USER_ROLE_CHANGED',
        actorUserId: actor.id,
        targetUserId: target.id,
        fromRole: target.role,
        toRole: requestedRole,
        metadata: { reason },
        createdAt: now,
      });

      return {
        id: target.id,
        email: target.email,
        displayName: target.displayName,
        photoUrl: target.photoUrl,
        role: requestedRole,
        createdAt: target.createdAt,
      };
    });
  }

  async getAuditHistory() {
    const snapshot = await this.firebase.db
      .collection(AUDIT_COLLECTION)
      .where('action', '==', 'USER_ROLE_CHANGED')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    const userIds = new Set<string>();
    const audits: AuditRecord[] = snapshot.docs.map((doc) => {
      const data = doc.data();
      if (data.actorUserId) userIds.add(data.actorUserId);
      if (data.targetUserId) userIds.add(data.targetUserId);
      return {
        id: doc.id,
        action: String(data.action),
        actorUserId: String(data.actorUserId),
        targetUserId: data.targetUserId ? String(data.targetUserId) : null,
        fromRole: (data.fromRole ?? null) as UserRole | null,
        toRole: (data.toRole ?? null) as UserRole | null,
        metadata: (data.metadata ?? null) as Record<string, unknown> | null,
        createdAt: toDate(data.createdAt),
      };
    });

    const users = await Promise.all([...userIds].map((id) => this.getById(id)));
    const byId = new Map(users.filter(Boolean).map((user) => [user!.id, user!]));

    return audits.map((audit) => ({
      ...audit,
      actor: byId.has(audit.actorUserId)
        ? {
            id: audit.actorUserId,
            displayName: byId.get(audit.actorUserId)!.displayName,
            email: byId.get(audit.actorUserId)!.email,
          }
        : null,
      targetUser: audit.targetUserId && byId.has(audit.targetUserId)
        ? {
            id: audit.targetUserId,
            displayName: byId.get(audit.targetUserId)!.displayName,
            email: byId.get(audit.targetUserId)!.email,
          }
        : null,
    }));
  }
}

export { searchTokensFor, USERS_COLLECTION, AUDIT_COLLECTION };
