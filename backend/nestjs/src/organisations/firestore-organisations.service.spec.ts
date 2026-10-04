import { NotFoundException } from '@nestjs/common';
import { FirestoreOrganisationsService } from './firestore-organisations.service';

describe('FirestoreOrganisationsService', () => {
  const get = jest.fn();
  const collection = jest.fn();
  const firebase:any = { db: { collection, getAll: jest.fn(), batch: jest.fn(() => ({ set:jest.fn(), update:jest.fn(), delete:jest.fn(), commit:jest.fn() })) } };

  beforeEach(() => {
    jest.clearAllMocks();
    collection.mockImplementation((name:string) => ({
      where: jest.fn().mockReturnThis(), orderBy: jest.fn().mockReturnThis(), limit: jest.fn().mockReturnThis(),
      get, doc: jest.fn((id:string) => ({ id, get, set:jest.fn(), update:jest.fn(), delete:jest.fn() })),
    }));
    get.mockResolvedValue({empty:false,docs:[]});
    firebase.db.getAll.mockResolvedValue([]);
    delete process.env.R2_PUBLIC_BASE_URL;
  });

  const org:any = (o:any={}) => ({
    id:'org-1',slug:'help',isActive:true,displayOrder:1,
    translations:{en:{name:'Help',description:'Support'}},causeIds:['c1'],media:[],
    logoUrl:null,websiteUrl:null,phone:null,mobileNumber:null,email:null,address:null,city:null,state:null,country:'IN',latitude:null,longitude:null,...o
  });

  it('covers public reads and missing cases', async () => {
    const s:any=new FirestoreOrganisationsService(firebase);
    get.mockResolvedValueOnce({docs:[{data:()=>org()}]});
    firebase.db.getAll.mockResolvedValueOnce([{id:'c1',exists:true,data:()=>({id:'c1',slug:'cause',isActive:true,displayOrder:1,translations:{en:{name:'Cause'}}})}]);
    await expect(s.findAll('en')).resolves.toEqual([expect.objectContaining({name:'Help',causes:[expect.objectContaining({id:'c1'})]})]);
    get.mockResolvedValueOnce({empty:false,docs:[{data:()=>org()}]});
    firebase.db.getAll.mockResolvedValue([]);
    await expect(s.findOne('help','hi')).resolves.toEqual(expect.objectContaining({name:'Help'}));
    get.mockResolvedValueOnce({empty:true,docs:[]});
    await expect(s.findOne('missing','en')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('covers CRUD and media administration flows', async () => {
    const s:any=new FirestoreOrganisationsService(firebase);
    const ref:any={id:'org-1',get:jest.fn().mockResolvedValue({exists:true,data:()=>org()}),set:jest.fn(),update:jest.fn(),delete:jest.fn()};
    collection.mockReturnValue({...collection('x'),doc:jest.fn(()=>ref)});
    get.mockResolvedValue({empty:true,docs:[]});
    await s.syncOrganisation({...org(),createdAt:new Date(),updatedAt:new Date()});
    await s.removeOrganisation('org-1');
    get.mockResolvedValue({docs:[{data:()=>org()}]}); await expect(s.findAllForAdmin()).resolves.toHaveLength(1);
    get.mockResolvedValue({exists:false}); await expect(s.findOneForAdmin('x')).rejects.toThrow(NotFoundException);
    get.mockResolvedValue({exists:true,data:()=>org()}); await expect(s.findOneForAdmin('org-1')).resolves.toEqual(org());
    get.mockResolvedValueOnce({empty:true,docs:[]}); await expect(s.create({translations:[{languageCode:'en',name:'New Org'}]})).resolves.toEqual(expect.objectContaining({slug:'new-org'}));
    get.mockResolvedValueOnce({empty:false,docs:[{id:'existing'}]}); await expect(s.create({slug:'existing',translations:[]})).rejects.toThrow();
    get.mockResolvedValue({exists:true,data:()=>org()}); await expect(s.update('org-1',{translations:[{languageCode:'en',name:'Updated'}]})).resolves.toEqual(expect.objectContaining({id:'org-1'}));
    get.mockResolvedValue({exists:false}); await expect(s.update('missing',{})).rejects.toThrow(NotFoundException);
    get.mockResolvedValue({exists:true,data:()=>org({causeIds:['c1','c1']})}); await expect(s.updateCauses('org-1',['c1','c1','c2'])).resolves.toEqual(expect.objectContaining({id:'org-1'}));
    get.mockResolvedValue({exists:false}); await expect(s.updateCauses('missing',['c1'])).rejects.toThrow(NotFoundException);
    const mediaRef:any={id:'m1',get:jest.fn().mockResolvedValue({exists:true,data:()=>({id:'m1',storageKey:'a.jpg',mimeType:'image/jpeg',width:10,height:20})})};
    collection.mockImplementation((name:string)=> name==='media'
      ? {doc:jest.fn(()=>mediaRef),where:jest.fn().mockReturnThis(),get:jest.fn().mockResolvedValue({empty:false,docs:[]})}
      : {where:jest.fn().mockReturnThis(),orderBy:jest.fn().mockReturnThis(),limit:jest.fn().mockReturnThis(),get,doc:jest.fn(()=>ref)});
    ref.get.mockResolvedValue({exists:true,data:()=>org({media:[{mediaId:'m1',purpose:'GALLERY',displayOrder:0,isPrimary:false}]})});
    firebase.db.getAll.mockResolvedValueOnce([mediaRef.get.mockResolvedValue ? {id:'m1',exists:true,data:()=>({id:'m1',storageKey:'a.jpg',mimeType:'image/jpeg',width:10,height:20})} : {}]);
    await expect(s.listMedia('org-1')).resolves.toHaveLength(1);
    ref.get.mockResolvedValue({exists:true,data:()=>org({media:[]})});
    mediaRef.get.mockResolvedValue({exists:true,data:()=>({id:'m1'})});
    await expect(s.attachMedia('org-1',{mediaId:'m1',purpose:'GALLERY',isPrimary:true})).resolves.toBeDefined();
    ref.get.mockResolvedValue({exists:true,data:()=>org({media:[{mediaId:'m1',purpose:'GALLERY',displayOrder:0,isPrimary:true}]})});
    await expect(s.attachMedia('org-1',{mediaId:'m1'})).rejects.toThrow();
    await expect(s.updateMedia('org-1','m1',{displayOrder:2})).resolves.toBeDefined();
    await expect(s.removeMedia('org-1','m1')).resolves.toEqual({id:'org-1',mediaId:'m1',deleted:true});
  });

  it('covers deactivation, activation and response/media helpers', async () => {
    const s:any=new FirestoreOrganisationsService(firebase);
    const ref:any={id:'org-1',get:jest.fn().mockResolvedValue({exists:true,data:()=>org()}),set:jest.fn(),update:jest.fn(),delete:jest.fn()};
    collection.mockImplementation((name:string)=>({
      where:jest.fn().mockReturnThis(),orderBy:jest.fn().mockReturnThis(),limit:jest.fn().mockReturnThis(),
      get: name==='beneficiaries' ? jest.fn().mockResolvedValue({empty:false,docs:[{}]}) :
        name==='donationAllocations' ? jest.fn().mockResolvedValue({empty:true,docs:[]}) : get,
      doc:jest.fn(()=>ref)
    }));
    await expect(s.removeOrDeactivate('org-1')).resolves.toEqual(expect.objectContaining({deactivated:true}));
    collection.mockImplementation((name:string)=>({where:jest.fn().mockReturnThis(),orderBy:jest.fn().mockReturnThis(),limit:jest.fn().mockReturnThis(),get:jest.fn().mockResolvedValue({empty:true,docs:[]}),doc:jest.fn(()=>ref)}));
    await expect(s.removeOrDeactivate('org-1')).resolves.toEqual(expect.objectContaining({deleted:true}));
    jest.spyOn(s,'findOneForAdmin').mockResolvedValue(org());
    await expect(s.setActive('org-1',false)).resolves.toEqual(org());
    const media={id:'m1',storageKey:'x.jpg',mimeType:'image/jpeg',width:10,height:20};
    expect(s.translation(undefined,'en')).toEqual({name:null,description:null});
    expect(s.translation({en:{name:'E'},hi:{name:'H'}},'hi')).toEqual({name:'H',description:null});
    process.env.R2_PUBLIC_BASE_URL='https://cdn.example/';
    expect(s.mediaUrl(media)).toBe('https://cdn.example/x.jpg');
    expect(s.primaryMediaUrl([{purpose:'LOGO',isPrimary:false,media}], 'LOGO')).toBe('https://cdn.example/x.jpg');
    expect(s.galleryMedia([{purpose:'GALLERY',displayOrder:2,media},{purpose:'GALLERY',displayOrder:1,media}], 'GALLERY')[0].id).toBe('m1');
    await expect(s.getByIds('media',[])).resolves.toEqual([]);
  });
});