import { Timestamp } from 'firebase-admin/firestore';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { FirestoreUsersService, searchTokensFor } from './firestore-users.service';

describe('FirestoreUsersService', () => {
  it('creates prefix search tokens for names and email values', () => {
    expect(searchTokensFor(['Nikita Sharma', 'Nikita@example.com'])).toEqual(
      expect.arrayContaining(['n', 'ni', 'nik', 'nikita', 's', 'sh', 'sha', 'nikita']),
    );
  });

  it('creates a new user from a Firebase identity with USER role', async () => {
    const userRef = { id: 'user-1' };
    const querySnapshot = { empty: true, docs: [] };
    const transaction = {
      get: jest.fn().mockResolvedValue(querySnapshot),
      set: jest.fn(),
      update: jest.fn(),
    };
    const collection = {
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      doc: jest.fn().mockReturnValue(userRef),
    };
    const db = {
      collection: jest.fn().mockReturnValue(collection),
      runTransaction: jest.fn(async (callback: any) => callback(transaction)),
    };

    const service = new FirestoreUsersService({ db } as any);
    const result = await service.upsertFromIdentity({
      uid: 'firebase-1',
      email: 'user@example.com',
      displayName: 'Test User',
    });

    expect(result.role).toBe('USER');
    expect(transaction.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        firebaseUid: 'firebase-1',
        role: 'USER',
      }),
    );
  });

  it('updates an existing user without changing their role', async () => {
    const existing = {
      id: 'user-1',
      firebaseUid: 'firebase-1',
      email: 'old@example.com',
      displayName: 'Old',
      photoUrl: null,
      role: 'ADMIN',
      preferredLanguage: null,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      searchTokens: [],
    };
    const transaction = {
      get: jest.fn().mockResolvedValue({ empty: false, docs: [{ ref: {}, data: () => existing }] }),
      set: jest.fn(),
      update: jest.fn(),
    };
    const collection = {
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
    };
    const db = {
      runTransaction: jest.fn(async (callback: any) => callback(transaction)),
      collection: jest.fn().mockReturnValue(collection),
    };
    const service = new FirestoreUsersService({ db } as any);

    const result = await service.upsertFromIdentity({
      uid: 'firebase-1',
      email: 'new@example.com',
      displayName: 'New',
    });

    expect(result.role).toBe('ADMIN');
    expect(transaction.update).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ email: 'new@example.com', displayName: 'New' }),
    );
  });
  it('covers reads, listing, role changes and audit history', async () => {
    const makeUser=(id:string,role:any='USER')=>({id,firebaseUid:id,email:id+'@x.com',displayName:id,photoUrl:null,role,preferredLanguage:null,createdAt:Timestamp.now(),updatedAt:Timestamp.now(),searchTokens:[id]});
    const actor=makeUser('actor','SUPER_ADMIN'), target=makeUser('target','USER');
    const targetRef:any={id:'target',get:jest.fn().mockResolvedValue({exists:true,id:'target',data:()=>target})};
    const q:any={where:jest.fn().mockReturnThis(),limit:jest.fn().mockReturnThis(),count:jest.fn().mockReturnThis(),orderBy:jest.fn().mockReturnThis(),offset:jest.fn().mockReturnThis(),get:jest.fn().mockResolvedValue({empty:false,docs:[],data:()=>({count:0})})};
    const tx:any={get:jest.fn().mockResolvedValue({exists:true,id:'target',data:()=>target}),set:jest.fn(),update:jest.fn()};
    const db:any={collection:jest.fn((n)=>n==='users'?{...q,doc:jest.fn(()=>targetRef)}:{...q,doc:jest.fn(()=>({id:'log'}))}),runTransaction:jest.fn(async(cb:any)=>cb(tx))};
    const service=new FirestoreUsersService({db} as any); jest.spyOn(service,'getByFirebaseUid').mockResolvedValue(actor);
    await service.listUsers({search:'abc',role:'USER',page:2,pageSize:99});
    expect((await service.changeRole('target','actor','ADMIN')).role).toBe('ADMIN');
    try { await service.changeRole('target','actor','BAD'); } catch (e) { expect(e).toBeInstanceOf(BadRequestException); }
    target.role='ADMIN'; try { await service.changeRole('target','actor','ADMIN'); } catch (e) { expect(e).toBeInstanceOf(ConflictException); }
    target.role='SUPER_ADMIN'; try { await service.changeRole('target','actor','USER'); } catch (e) { expect(e).toBeInstanceOf(BadRequestException); }
    target.role='USER'; jest.spyOn(service,'getByFirebaseUid').mockResolvedValue(null); try { await service.changeRole('target','actor','ADMIN'); } catch (e) { expect(e).toBeInstanceOf(NotFoundException); }
    expect(await service.getAuditHistory()).toEqual([]);
  });

});
