import { NotFoundException } from '@nestjs/common';
import { FirestoreMediaService } from './firestore-media.service';

describe('FirestoreMediaService', () => {
  const media = { id:'m1', uploadedById:'u1', storageKey:'images/a.jpg', mimeType:'image/jpeg', fileSize:100, width:100, height:80, createdAt:new Date(), updatedAt:new Date() };
  function makeDb(snapshot:any={exists:true,data:()=>media}) {
    const ref={get:jest.fn().mockResolvedValue(snapshot),set:jest.fn().mockResolvedValue(undefined),delete:jest.fn().mockResolvedValue(undefined)};
    const db={collection:jest.fn().mockReturnValue({doc:jest.fn().mockReturnValue(ref)})};
    return {db,ref};
  }
  it('upserts media and converts dates to Firestore timestamps',async()=>{const {db,ref}=makeDb();const service=new FirestoreMediaService({db} as any);await expect(service.upsert(media)).resolves.toEqual(media);expect(ref.set).toHaveBeenCalledWith(expect.objectContaining({id:'m1',createdAt:expect.anything()}),{merge:true});});
  it('reads existing media',async()=>{const {db}=makeDb();const service=new FirestoreMediaService({db} as any);await expect(service.getById('m1')).resolves.toEqual(media);});
  it('throws for missing media',async()=>{const {db}=makeDb({exists:false});const service=new FirestoreMediaService({db} as any);await expect(service.getById('missing')).rejects.toBeInstanceOf(NotFoundException);});
  it('deletes media',async()=>{const {db,ref}=makeDb();const service=new FirestoreMediaService({db} as any);await service.delete('m1');expect(ref.delete).toHaveBeenCalled();});
});