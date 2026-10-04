import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { FirestoreCausesService } from './firestore-causes.service';

describe('FirestoreCausesService',()=>{
  let collections:any; let firebase:any; let service:any;
  const cause=(o:any={})=>({id:'c1',slug:'root',parentId:null,isActive:true,displayOrder:1,translations:{en:{name:'Root',description:'Desc'}},childIds:[],organisationIds:[],...o});
  beforeEach(()=>{
    jest.clearAllMocks(); collections=new Map();
    firebase={db:{collection:jest.fn((name:string)=>{if(!collections.has(name)){const c:any={where:jest.fn().mockReturnThis(),orderBy:jest.fn().mockReturnThis(),limit:jest.fn().mockReturnThis(),get:jest.fn().mockResolvedValue({empty:true,docs:[]}),doc:jest.fn((id:string)=>({id,get:jest.fn().mockResolvedValue({exists:false}),set:jest.fn(),update:jest.fn(),delete:jest.fn()}))};collections.set(name,c);}return collections.get(name)}),getAll:jest.fn().mockResolvedValue([]),batch:jest.fn(()=>({set:jest.fn(),update:jest.fn(),delete:jest.fn(),commit:jest.fn()}))}};
    service=new FirestoreCausesService(firebase);
    delete process.env.R2_PUBLIC_BASE_URL;
  });

  it('covers sync/admin/create/setActive and validation',async()=>{
    const causes=firebase.db.collection('causes');
    await service.syncCauses([cause({id:'c1',createdAt:new Date(),updatedAt:new Date()})]);
    causes.get.mockResolvedValue({docs:[{data:()=>cause()}]}); await expect(service.findAllForAdmin()).resolves.toHaveLength(1);
    causes.doc.mockImplementation((id:string)=>({id,get:jest.fn().mockResolvedValue({exists:false}),set:jest.fn(),update:jest.fn()}));
    await expect(service.findOneForAdmin('missing')).rejects.toThrow(NotFoundException);
    const ref:any={id:'c1',get:jest.fn().mockResolvedValue({exists:true,data:()=>cause()}),set:jest.fn(),update:jest.fn()};
    causes.doc.mockReturnValue(ref); causes.get.mockResolvedValue({docs:[{data:()=>cause()}]});
    await expect(service.findOneForAdmin('c1')).resolves.toEqual(expect.objectContaining({id:'c1'}));
    expect(()=>service.validateAdminTranslations([])).toThrow(BadRequestException);
    expect(()=>service.validateAdminTranslations([{languageCode:'en',name:'A'},{languageCode:'en',name:'B'}])).toThrow(BadRequestException);
    expect(()=>service.validateAdminTranslations([{languageCode:'en',name:' '}])).toThrow(BadRequestException);
    service.validateAdminTranslations([{languageCode:'en',name:'A'}]);
    causes.get.mockResolvedValueOnce({empty:true,docs:[]}); await expect(service.create({slug:'new',translations:[{languageCode:'en',name:'New'}]})).resolves.toEqual(expect.objectContaining({slug:'new'}));
    causes.get.mockResolvedValueOnce({empty:false,docs:[{id:'dup'}]}); await expect(service.create({slug:'dup',translations:[{languageCode:'en',name:'Dup'}]})).rejects.toThrow(ConflictException);
    causes.get.mockResolvedValueOnce({empty:true,docs:[]}); causes.doc.mockImplementation((id:string)=>({id,get:jest.fn().mockResolvedValue({exists:false}),set:jest.fn(),update:jest.fn()}));
    await expect(service.create({slug:'child',parentId:'missing',translations:[{languageCode:'en',name:'Child'}]})).rejects.toThrow(BadRequestException);
    causes.doc.mockReturnValue(ref); causes.get.mockResolvedValue({docs:[{data:()=>cause()}]}); await expect(service.setActive('c1',false)).resolves.toBeDefined();
    ref.get.mockResolvedValue({exists:false}); await expect(service.setActive('c1',false)).rejects.toThrow(NotFoundException);
  });

  it('covers updates, parent relations and conflicts',async()=>{
    const causes=firebase.db.collection('causes'); const ref:any={id:'c1',get:jest.fn().mockResolvedValue({exists:true,data:()=>cause({parentId:'old'})}),set:jest.fn(),update:jest.fn()};
    causes.doc.mockImplementation((id:string)=> id==='c1'?ref:{id,get:jest.fn().mockResolvedValue({exists:true}),set:jest.fn(),update:jest.fn()});
    causes.get.mockResolvedValue({docs:[{data:()=>cause({parentId:'old'})}]});
    await expect(service.update('c1',{slug:'new',parentId:'new-parent',displayOrder:3,isActive:false,translations:[{languageCode:'en',name:'New'}]})).resolves.toBeDefined();
    causes.get.mockResolvedValueOnce({empty:false,docs:[{id:'other'}]}); await expect(service.update('c1',{slug:'other'})).rejects.toThrow(ConflictException);
    ref.get.mockResolvedValue({exists:true,data:()=>cause({parentId:null})}); causes.get.mockResolvedValue({docs:[{data:()=>cause({parentId:null})}]});
    await expect(service.update('c1',{parentId:'c1'})).rejects.toThrow(BadRequestException);
    ref.get.mockResolvedValue({exists:true,data:()=>cause({parentId:null})}); causes.doc.mockImplementation((id:string)=>({id,get:jest.fn().mockResolvedValue({exists:false}),set:jest.fn(),update:jest.fn()}));
    await expect(service.update('c1',{parentId:'missing'})).rejects.toThrow(BadRequestException);
    void causes;
  });

  it('covers public cause mapping, organisations, media and chunking',async()=>{
    const causes=firebase.db.collection('causes');
    const root=cause({childIds:['c2','inactive']}); const child=cause({id:'c2',slug:'child',parentId:'c1',displayOrder:2,translations:{en:{name:'Child'}}}); const inactive=cause({id:'inactive',isActive:false,parentId:'c1'});
    causes.get.mockResolvedValueOnce({docs:[{data:()=>root}]});
    firebase.db.getAll.mockResolvedValueOnce([{id:'c2',exists:true,data:()=>child},{id:'inactive',exists:true,data:()=>inactive}]);
    await expect(service.findAll('en')).resolves.toEqual([expect.objectContaining({children:[expect.objectContaining({id:'c2'})]})]);
    causes.get.mockResolvedValueOnce({empty:false,docs:[{data:()=>root}]});
    firebase.db.getAll.mockImplementation(async(...refs:any[])=>refs.map(r=>({id:r.id,exists:true,data:()=>r.id==='c2'?child:({id:'o1',slug:'org',isActive:true,displayOrder:1,causeIds:['c1'],translations:{en:{name:'Org'}},media:[{mediaId:'m1',purpose:'LOGO',displayOrder:0,isPrimary:true},{mediaId:'m2',purpose:'GALLERY',displayOrder:1,isPrimary:false}]})})));
    firebase.db.collection('organisations').get.mockResolvedValue({docs:[]});
    firebase.db.collection('media').get.mockResolvedValue({docs:[]});
    await expect(service.findOne('root','en')).resolves.toEqual(expect.objectContaining({id:'c1'}));
    causes.get.mockResolvedValueOnce({empty:true,docs:[]}); await expect(service.findOne('missing','en')).rejects.toThrow(NotFoundException);
    expect(service.displayOrderForOrganisation([{id:'o',displayOrder:3}],'x')).toBe(Number.MAX_SAFE_INTEGER);
    expect(service.translation(undefined,'en')).toEqual({name:null,description:null});
    process.env.R2_PUBLIC_BASE_URL='https://cdn.example/'; expect(service.mediaUrl({storageKey:'x'})).toBe('https://cdn.example/x');
    expect(service.primaryMediaUrl([{purpose:'LOGO',isPrimary:false,media:{id:'m',storageKey:'x'}}],'LOGO')).toBe('https://cdn.example/x');
    expect(service.galleryMedia([{purpose:'GALLERY',displayOrder:2,media:{id:'m2',storageKey:'y',mimeType:'image/jpeg',width:1,height:2}},{purpose:'GALLERY',displayOrder:1,media:{id:'m1',storageKey:'x',mimeType:'image/png',width:3,height:4}}],'GALLERY')).toHaveLength(2);
    await expect(service.getByIds('causes',[])).resolves.toEqual([]);
    firebase.db.getAll.mockResolvedValue([{id:'a',exists:true,data:()=>cause({id:'a'})},{id:'missing',exists:false,data:()=>undefined}]);
    await expect(service.getByIds('causes',['a','a','missing'])).resolves.toHaveLength(1);
    await expect(service.getMediaByIds([])).resolves.toEqual([]);
    firebase.db.getAll.mockResolvedValue([{id:'m',exists:true,data:()=>({id:'m',storageKey:'x',mimeType:'image/jpeg',width:1,height:1})},{id:'z',exists:false}]);
    await expect(service.getMediaByIds(['m','z'])).resolves.toHaveLength(1);
  });

  it('covers admin response recursion and organisation media response',async()=>{
    const parent=cause({id:'p',slug:'parent',childIds:['c']}); const child=cause({id:'c',slug:'child',parentId:'p',displayOrder:1,translations:{en:{name:'Child',description:null}}});
    const mapped=service.adminResponse(parent,new Map([['p',parent],['c',child]]));
    expect(mapped.parent).toBeNull(); expect(mapped.children[0].id).toBe('c'); expect(mapped.children[0].parent.slug).toBe('parent');
    firebase.db.getAll.mockResolvedValue([{id:'m1',exists:true,data:()=>({id:'m1',storageKey:'logo.jpg',mimeType:'image/jpeg',width:10,height:10})},{id:'m2',exists:true,data:()=>({id:'m2',storageKey:'g.jpg',mimeType:'image/png',width:20,height:20})}]);
    const r=await service.organisationResponse({id:'o',slug:'org',isActive:true,displayOrder:1,translations:{en:{name:'Org'}},media:[{mediaId:'m1',purpose:'LOGO',displayOrder:0,isPrimary:true},{mediaId:'m2',purpose:'GALLERY',displayOrder:1,isPrimary:false}]},'en');
    expect(r.logoUrl).toContain('logo.jpg'); expect(r.gallery).toHaveLength(1);
  });
});