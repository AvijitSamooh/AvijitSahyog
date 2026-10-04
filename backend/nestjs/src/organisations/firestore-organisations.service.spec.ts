import { NotFoundException } from '@nestjs/common';
import { FirestoreOrganisationsService } from './firestore-organisations.service';

describe('FirestoreOrganisationsService', () => {
  let collections:any;
  let firebase:any;
  let service:any;
  const org=(o:any={})=>({id:'org-1',slug:'help',isActive:true,displayOrder:1,translations:{en:{name:'Help',description:'Support'}},causeIds:['c1'],media:[],logoUrl:null,websiteUrl:null,phone:null,mobileNumber:null,email:null,address:null,city:null,state:null,country:'IN',latitude:null,longitude:null,...o});

  beforeEach(()=>{
    jest.clearAllMocks(); collections=new Map();
    firebase={db:{collection:jest.fn((name:string)=>{
      if(!collections.has(name)){
        const c:any={where:jest.fn().mockReturnThis(),orderBy:jest.fn().mockReturnThis(),limit:jest.fn().mockReturnThis(),get:jest.fn().mockResolvedValue({empty:true,docs:[]}),doc:jest.fn((id:string)=>({id,get:jest.fn().mockResolvedValue({exists:false}),set:jest.fn(),update:jest.fn(),delete:jest.fn()}))};
        collections.set(name,c);
      } return collections.get(name);
    }),getAll:jest.fn().mockResolvedValue([])}};
    service=new FirestoreOrganisationsService(firebase);
    delete process.env.R2_PUBLIC_BASE_URL;
  });

  it('covers public reads, admin reads and missing cases',async()=>{
    const orgs=firebase.db.collection('organisations');
    orgs.get.mockResolvedValueOnce({docs:[{data:()=>org()}]});
    firebase.db.getAll.mockResolvedValueOnce([{id:'c1',exists:true,data:()=>({id:'c1',slug:'cause',isActive:true,displayOrder:1,translations:{en:{name:'Cause'}}})}]);
    await expect(service.findAll('en')).resolves.toEqual([expect.objectContaining({name:'Help',causes:[expect.objectContaining({id:'c1'})]})]);
    orgs.get.mockResolvedValueOnce({empty:false,docs:[{data:()=>org()}]}); firebase.db.getAll.mockResolvedValue([]);
    await expect(service.findOne('help','hi')).resolves.toEqual(expect.objectContaining({name:'Help'}));
    orgs.get.mockResolvedValueOnce({empty:true,docs:[]}); await expect(service.findOne('missing','en')).rejects.toBeInstanceOf(NotFoundException);
    orgs.get.mockResolvedValue({docs:[{data:()=>org()}]}); await expect(service.findAllForAdmin()).resolves.toHaveLength(1);
    orgs.doc.mockImplementation((id:string)=>({id,get:jest.fn().mockResolvedValue({exists:false}),set:jest.fn(),update:jest.fn(),delete:jest.fn()}));
    await expect(service.findOneForAdmin('x')).rejects.toThrow(NotFoundException);
  });

  it('covers CRUD, cause and media administration',async()=>{
    const orgs=firebase.db.collection('organisations');
    const ref:any={id:'org-1',get:jest.fn().mockResolvedValue({exists:true,data:()=>org()}),set:jest.fn(),update:jest.fn(),delete:jest.fn()};
    orgs.doc.mockReturnValue(ref); orgs.get.mockResolvedValue({exists:true,empty:true,docs:[]});
    await service.syncOrganisation({...org(),createdAt:new Date(),updatedAt:new Date()}); await service.removeOrganisation('org-1');
    await expect(service.findOneForAdmin('org-1')).resolves.toEqual(org());
    await expect(service.create({translations:[{languageCode:'en',name:'New Org'}]})).resolves.toEqual(expect.objectContaining({slug:'new-org'}));
    orgs.get.mockResolvedValueOnce({empty:false,docs:[{id:'dup'}]}); await expect(service.create({slug:'dup',translations:[]})).rejects.toThrow();
    orgs.get.mockResolvedValue({exists:true,data:()=>org()}); await expect(service.update('org-1',{translations:[{languageCode:'en',name:'Updated'}]})).resolves.toEqual(expect.objectContaining({id:'org-1'}));
    orgs.get.mockResolvedValue({exists:false}); await expect(service.update('missing',{})).rejects.toThrow(NotFoundException);
    orgs.get.mockResolvedValue({exists:true,data:()=>org()}); await expect(service.updateCauses('org-1',['c1','c1','c2'])).resolves.toEqual(expect.objectContaining({id:'org-1'}));
    orgs.get.mockResolvedValue({exists:false}); await expect(service.updateCauses('missing',['c1'])).rejects.toThrow(NotFoundException);
    const media=firebase.db.collection('media'); const mediaRef:any={id:'m1',get:jest.fn().mockResolvedValue({exists:true,data:()=>({id:'m1',storageKey:'a.jpg',mimeType:'image/jpeg',width:10,height:20})})}; media.doc.mockReturnValue(mediaRef);
    firebase.db.getAll.mockResolvedValue([{id:'m1',exists:true,data:()=>({id:'m1',storageKey:'a.jpg',mimeType:'image/jpeg',width:10,height:20})}]);
    ref.get.mockResolvedValue({exists:true,data:()=>org({media:[{mediaId:'m1',purpose:'GALLERY',displayOrder:0,isPrimary:false}]})});
    await expect(service.listMedia('org-1')).resolves.toEqual([expect.objectContaining({media:expect.objectContaining({id:'m1'})})]);
    ref.get.mockResolvedValue({exists:true,data:()=>org({media:[]})});
    await expect(service.attachMedia('org-1',{mediaId:'m1',purpose:'GALLERY',isPrimary:true})).resolves.toBeDefined();
    ref.get.mockResolvedValue({exists:true,data:()=>org({media:[{mediaId:'m1',purpose:'GALLERY',displayOrder:0,isPrimary:true}]})});
    await expect(service.attachMedia('org-1',{mediaId:'m1'})).rejects.toThrow();
    await expect(service.updateMedia('org-1','m1',{displayOrder:2})).resolves.toBeDefined();
    await expect(service.removeMedia('org-1','m1')).resolves.toEqual({id:'org-1',mediaId:'m1',deleted:true});
    mediaRef.get.mockResolvedValue({exists:false}); ref.get.mockResolvedValue({exists:true,data:()=>org({media:[]})});
    await expect(service.attachMedia('org-1',{mediaId:'missing'})).rejects.toThrow(NotFoundException);
  });

  it('covers lifecycle toggles and mapping helpers',async()=>{
    const orgs=firebase.db.collection('organisations'); const ref:any={id:'org-1',get:jest.fn().mockResolvedValue({exists:true,data:()=>org()}),set:jest.fn(),update:jest.fn(),delete:jest.fn()}; orgs.doc.mockReturnValue(ref);
    firebase.db.collection('beneficiaries').get.mockResolvedValue({empty:false,docs:[{}]});
    await expect(service.removeOrDeactivate('org-1')).resolves.toEqual(expect.objectContaining({deactivated:true}));
    firebase.db.collection('beneficiaries').get.mockResolvedValue({empty:true,docs:[]}); firebase.db.collection('donationAllocations').get.mockResolvedValue({empty:true,docs:[]});
    await expect(service.removeOrDeactivate('org-1')).resolves.toEqual(expect.objectContaining({deleted:true}));
    jest.spyOn(service,'findOneForAdmin').mockResolvedValue(org());
    await expect(service.setActive('org-1',false)).resolves.toEqual(org());
    const media={id:'m1',storageKey:'x.jpg',mimeType:'image/jpeg',width:10,height:20};
    expect(service.translation(undefined,'en')).toEqual({name:null,description:null});
    expect(service.translation({en:{name:'E'},hi:{name:'H'}},'hi')).toEqual({name:'H',description:null});
    process.env.R2_PUBLIC_BASE_URL='https://cdn.example/';
    expect(service.mediaUrl(media)).toBe('https://cdn.example/x.jpg');
    expect(service.primaryMediaUrl([{purpose:'LOGO',isPrimary:false,media}], 'LOGO')).toBe('https://cdn.example/x.jpg');
    expect(service.galleryMedia([{purpose:'GALLERY',displayOrder:2,media},{purpose:'GALLERY',displayOrder:1,media}], 'GALLERY')[0].id).toBe('m1');
    await expect(service.getByIds('media',[])).resolves.toEqual([]);
    firebase.db.getAll.mockResolvedValue([[{id:'m1',exists:true,data:()=>media}]].flat());
    await expect(service.getByIds('media',['m1','m1','missing'])).resolves.toHaveLength(1);
  });
});