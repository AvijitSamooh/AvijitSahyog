import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirestoreHelpApplicationsService } from './firestore-help-applications.service';
import { HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { HelpApplicationDecisionDto } from './dto/review-help-application.dto';

describe('FirestoreHelpApplicationsService coverage', () => {
  const id = { uid: 'uid-1' } as any;
  const base = (overrides: any = {}) => ({
    id: 'app-1', applicantId: 'u1', applicantName: 'Alice', mobileNumber: '9876543210',
    email: 'a@x', address: 'Long address', city: 'Pune', state: 'MH', pincode: '411001',
    type: HelpApplicationTypeDto.MEDICAL_HELP, status: 'SUBMITTED', requestedAmount: 100,
    overallPercentage: 91, approvedAmount: null, rejectionReason: null, clarification: null,
    motherName: null, fatherName: null, dateOfBirth: Timestamp.now(), classStandard: null,
    schoolInstituteName: null, accomplishments: null, certificatePhotoMediaId: null,
    facePhotoMediaId: 'face-1', adminNote: null, submittedAt: Timestamp.now(),
    reviewedAt: null, createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    media: [{ mediaId: 'm1' }], ruleAcceptances: [{ ruleId: 'r1', ruleText: 'Rule' }],
    ...overrides,
  });

  function makeService() {
    const refs = new Map<string, any>();
    const collections = new Map<string, any>();
    const collection = jest.fn((name: string) => {
      if (!collections.has(name)) {
        const c: any = {
          where: jest.fn().mockReturnThis(), orderBy: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn().mockResolvedValue({ empty: true, size: 0, docs: [] }),
          doc: jest.fn((docId: string) => {
            if (!refs.has(name + ':' + docId)) refs.set(name + ':' + docId, {
              id: docId, get: jest.fn().mockResolvedValue({ exists: false }),
              set: jest.fn(), update: jest.fn(), delete: jest.fn(), ref: { id: docId },
            });
            return refs.get(name + ':' + docId);
          }),
        };
        collections.set(name, c);
      }
      return collections.get(name);
    });
    const db: any = {
      collection, batch: jest.fn(() => ({ set: jest.fn(), update: jest.fn(), delete: jest.fn(), commit: jest.fn() })),
    };
    const deps: any = {
      firebase: { db },
      users: {
        upsertFromIdentity: jest.fn().mockResolvedValue({ id: 'u1', role: 'ADMIN', displayName: 'Admin', email: 'a@x' }),
        getById: jest.fn().mockResolvedValue({ id: 'u1', displayName: 'Admin', email: 'a@x' }),
      },
      media: { getById: jest.fn().mockResolvedValue({ id: 'm1', storageKey: 'x.jpg', mimeType: 'image/jpeg', width: 100, height: 100 }) },
      mediaService: { downloadImage: jest.fn().mockResolvedValue(Buffer.from('bad')), deleteUserImage: jest.fn() },
      beneficiaries: { syncBeneficiary: jest.fn() },
      windows: { ensureAccepting: jest.fn() },
      rules: { listForAcceptance: jest.fn().mockResolvedValue([{ id: 'r1', text: 'Rule' }]) },
    };
    return { service: new FirestoreHelpApplicationsService(deps.firebase, deps.users, deps.media, deps.mediaService, deps.beneficiaries, deps.windows, deps.rules), db, deps, collections, refs };
  }

  it('covers validation and response helpers', async () => {
    const { service } = makeService(); const s: any = service;
    s.validateApplicantDetails({ applicantName:'Alice', mobileNumber:'9876543210', address:'Long', city:'Pune', state:'MH', pincode:'411001' });
    s.validateSubmission(HelpApplicationTypeDto.MEDICAL_HELP, 100, ['m1']);
    s.validateSubmission(HelpApplicationTypeDto.PRATIBHA_SAMMAN, undefined, ['m1']);
    s.validatePratibhaDetails(HelpApplicationTypeDto.MEDICAL_HELP, {});
    s.validatePratibhaDetails(HelpApplicationTypeDto.PRATIBHA_SAMMAN, {
      motherName:'M', fatherName:'F', dateOfBirth:'2008-01-01', classStandard:'10', schoolInstituteName:'School', certificatePhotoMediaId:'c1'
    });
    expect(() => s.validateApplicantDetails({applicantName:'',mobileNumber:'1',address:'',city:'',state:'',pincode:'x'})).toThrow(BadRequestException);
    expect(() => s.validateSubmission(HelpApplicationTypeDto.MEDICAL_HELP, 0, [])).toThrow(BadRequestException);
    expect(() => s.validatePratibhaDetails(HelpApplicationTypeDto.PRATIBHA_SAMMAN, {})).toThrow(BadRequestException);
    expect(() => s.validatePratibhaDetails(HelpApplicationTypeDto.PRATIBHA_SAMMAN, {
      motherName:'M',fatherName:'F',dateOfBirth:'bad',classStandard:'10',schoolInstituteName:'S',certificatePhotoMediaId:'c'
    })).toThrow(BadRequestException);
    const r = await s.toResponse(base()); expect(r.media[0].id).toBe('m1');
    expect(s.baseResponse(base()).id).toBe('app-1');
    expect(s.name({ applicantName:'' })).toBe('Applicant');
    expect(s.date(null)).toBe(0); expect(s.date(Timestamp.now())).toBeGreaterThan(0);
    expect(s.dateValue(null)).toBeNull(); expect(s.dateValue(new Date())).toBeInstanceOf(Date);
    expect(s.dateValue({ toDate: () => new Date(0) })).toEqual(new Date(0));
  });

  it('covers media/rules/admin helpers and failure paths', async () => {
    const { service, deps, db, collections, refs } = makeService(); const s: any = service;
    await expect(s.validateMedia([], 'u1')).rejects.toThrow(BadRequestException);
    await expect(s.validateMedia(new Array(11).fill('m'), 'u1')).rejects.toThrow(BadRequestException);
    collections.set('media', { doc: jest.fn((x:string)=>({get:jest.fn().mockResolvedValue({exists:true,data:()=>({uploadedById:x==='m1'?'u1':'other'})})})) });
    await expect(s.validateMedia(['m1','m2'], 'u1')).rejects.toThrow(BadRequestException);
    await expect(s.validateMedia(['m1'], 'u1')).resolves.toEqual(['m1']);
    await expect(s.validateFacePhoto(undefined,'u1')).rejects.toThrow(BadRequestException);
    await expect(s.validateFacePhoto('m1','u1')).resolves.toBe('m1');
    await expect(s.validateCertificatePhoto(HelpApplicationTypeDto.MEDICAL_HELP,undefined,'u1')).resolves.toBeNull();
    await expect(s.validateCertificatePhoto(HelpApplicationTypeDto.PRATIBHA_SAMMAN,undefined,'u1')).rejects.toThrow(BadRequestException);
    await expect(s.validateCertificatePhoto(HelpApplicationTypeDto.PRATIBHA_SAMMAN,'m1','u1')).resolves.toBe('m1');
    await expect(s.validateAcceptedRules(HelpApplicationTypeDto.MEDICAL_HELP,['bad'])).rejects.toThrow(BadRequestException);
    await expect(s.validateAcceptedRules(HelpApplicationTypeDto.MEDICAL_HELP,['r1'])).resolves.toHaveLength(1);
    deps.users.upsertFromIdentity.mockResolvedValueOnce({id:'u1',role:'USER'}).mockResolvedValueOnce({id:'u1',role:'SUPER_ADMIN'});
    await expect(s.admin(id)).rejects.toThrow(BadRequestException); await expect(s.admin(id)).resolves.toEqual(expect.objectContaining({role:'SUPER_ADMIN'}));
    const ref=refs.get('helpApplications:x') || collections.get('helpApplications').doc('x');
    ref.get.mockResolvedValue({exists:false}); await expect(s.application('x')).rejects.toThrow(NotFoundException);
    expect(await s.mediaResponse('m1')).toEqual(expect.objectContaining({url:'x.jpg'}));
    process.env.R2_PUBLIC_BASE_URL='https://cdn.example/';
    expect((await s.mediaResponse('m1')).url).toBe('https://cdn.example/x.jpg'); delete process.env.R2_PUBLIC_BASE_URL;
  });

  it('covers create/list/find/update/delete/resubmit flows', async () => {
    const { service, db, deps, collections, refs } = makeService(); const s:any=service;
    jest.spyOn(s,'user').mockResolvedValue({id:'u1'}); jest.spyOn(s,'validateAcceptedRules').mockResolvedValue([{id:'r1',text:'Rule'}]);
    jest.spyOn(s,'validateMedia').mockResolvedValue(['m1']); jest.spyOn(s,'validateFacePhoto').mockResolvedValue('face-1');
    jest.spyOn(s,'validateCertificatePhoto').mockResolvedValue(null); jest.spyOn(s,'toResponse').mockResolvedValue({ok:true});
    const dto:any={type:HelpApplicationTypeDto.MEDICAL_HELP,applicantName:' Alice ',mobileNumber:' 9876543210 ',email:' a@x ',address:' Address ',city:' Pune ',state:' MH ',pincode:'411001',requestedAmount:100,overallPercentage:88,mediaIds:['m1'],facePhotoMediaId:'face-1',acceptedRuleIds:['r1']};
    await expect(s.create(id,dto)).resolves.toEqual({ok:true});
    const apps=collections.get('helpApplications'); apps.get.mockResolvedValue({docs:[{data:()=>base()},{data:()=>base({id:'app-2'})}]});
    jest.spyOn(s,'toResponses').mockResolvedValue([{id:'app-1'}]); await expect(s.listMine(id)).resolves.toEqual([{id:'app-1'}]);
    jest.spyOn(s,'application').mockResolvedValue(base()); await expect(s.findMine(id,'app-1')).resolves.toEqual({ok:true});
    jest.spyOn(s,'application').mockResolvedValue(base({applicantId:'other'})); await expect(s.findMine(id,'app-1')).rejects.toThrow(NotFoundException);
    jest.spyOn(s,'application').mockResolvedValue(base({status:'SUBMITTED'})); jest.spyOn(s,'toResponse').mockResolvedValue({ok:true});
    const updateDto:any={applicantName:' Alice2 ',mobileNumber:'9876543211',address:' Address ',city:'Pune',state:'MH',pincode:'411001',requestedAmount:120,overallPercentage:92,mediaIds:['m2'],facePhotoMediaId:'face-2',acceptedRuleIds:['r1'],email:'x@y',clarification:' ok '};
    deps.mediaService.deleteUserImage.mockRejectedValueOnce(new Error('ignore'));
    await expect(s.updateMine(id,'app-1',updateDto)).resolves.toEqual({ok:true});
    jest.spyOn(s,'application').mockResolvedValue(base({status:'APPROVED_FOR_DONATION'})); await expect(s.updateMine(id,'app-1',updateDto)).rejects.toThrow(BadRequestException);
    jest.spyOn(s,'application').mockResolvedValue(base()); const votes=[{ref:{id:'v1'}}]; apps.where.mockReturnThis(); apps.get.mockResolvedValue({size:1,docs:votes});
    await expect(s.deleteMine(id,'app-1')).resolves.toEqual({id:'app-1',deleted:true});
    jest.spyOn(s,'application').mockResolvedValue(base({status:'REJECTED'})); await expect(s.resubmit(id,'app-1',{requestedAmount:110,mediaIds:['m1'],certificatePhotoMediaId:null,acceptedRuleIds:['r1'],clarification:'fixed'} as any)).resolves.toEqual({ok:true});
    jest.spyOn(s,'application').mockResolvedValue(base({status:'SUBMITTED'})); await expect(s.resubmit(id,'app-1',{requestedAmount:110,mediaIds:['m1'],acceptedRuleIds:['r1'],clarification:'x'} as any)).rejects.toThrow(BadRequestException);
    jest.spyOn(s,'application').mockResolvedValue(base({applicantId:'other'})); await expect(s.deleteMine(id,'app-1')).rejects.toThrow(NotFoundException);
    void db;
  });

  it('covers admin lists, summaries, photo exports and voting', async () => {
    const { service, db, collections, refs, deps } = makeService(); const s:any=service;
    const a=base({id:'a',applicantName:'Zed',overallPercentage:80,createdAt:new Date(2),submittedAt:new Date(2)});
    const b=base({id:'b',applicantName:'Amy',overallPercentage:95,createdAt:new Date(1),submittedAt:new Date(1),type:HelpApplicationTypeDto.PRATIBHA_SAMMAN,status:'CONSIDERED_FOR_SAMMAN',certificatePhotoMediaId:null});
    const apps=collections.get('helpApplications'); apps.get.mockResolvedValue({docs:[{data:()=>a},{data:()=>b}]});
    jest.spyOn(s,'toAdminResponses').mockResolvedValue([{...a,voteAverage:2},{...b,voteAverage:5}]);
    await expect(s.listForAdmin()).resolves.toHaveLength(2); await expect(s.listForAdmin(HelpApplicationTypeDto.PRATIBHA_SAMMAN)).resolves.toHaveLength(2);
    await expect(s.adminSummary()).resolves.toEqual(expect.objectContaining({total:2}));
    jest.spyOn(s,'filtered').mockResolvedValue([base({id:'a',certificatePhotoMediaId:null}),base({id:'b',certificatePhotoMediaId:'c1'})]);
    await expect(s.certificatePhotoExportSummary()).resolves.toEqual(expect.objectContaining({total:2,available:1}));
    apps.get.mockResolvedValue({docs:[{data:()=>base({facePhotoMediaId:'m1',certificatePhotoMediaId:'m2'})}]});
    await expect(s.photoManifest()).resolves.toEqual([expect.objectContaining({id:'app-1',facePhoto:expect.any(Object)})]);
    jest.spyOn(s,'filtered').mockResolvedValue([base({id:'m',certificatePhotoMediaId:null}),base({id:'f',certificatePhotoMediaId:'bad'})]);
    deps.media.getById.mockRejectedValueOnce(new Error('read failed'));
    const zip=await s.buildCertificatePhotoExport(); expect(Buffer.isBuffer(zip)).toBe(true);
    const appRef=refs.get('helpApplications:app-1'); appRef.get.mockResolvedValue({exists:true,data:()=>base({status:'SUBMITTED'})});
    const voteRef=refs.get('helpApplicationVotes:app-1_u1') || collections.get('helpApplicationVotes').doc('app-1_u1');
    await expect(s.vote(id,'app-1',{score:5,comment:' good '} as any)).resolves.toEqual(expect.objectContaining({score:5,comment:'good'}));
    void db;
  });

  it('covers review decisions and status/publication helpers', async () => {
    const { service, collections, refs, deps } = makeService(); const s:any=service;
    jest.spyOn(s,'application').mockResolvedValue(base({type:HelpApplicationTypeDto.MEDICAL_HELP,requestedAmount:100}));
    jest.spyOn(s,'updateStatus').mockResolvedValue({ok:true});
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.APPROVE,approvedAmount:50} as any)).resolves.toEqual({ok:true});
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.APPROVE,approvedAmount:0} as any)).rejects.toThrow(BadRequestException);
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.REJECT,reason:' no '} as any)).resolves.toEqual({ok:true});
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.REJECT} as any)).rejects.toThrow(BadRequestException);
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.CLARIFICATION_REQUIRED,reason:'more'} as any)).resolves.toEqual({ok:true});
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.CLARIFICATION_REQUIRED} as any)).rejects.toThrow(BadRequestException);
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.CONSIDER_FOR_SAMMAN} as any)).rejects.toThrow(BadRequestException);
    jest.spyOn(s,'application').mockResolvedValue(base({type:HelpApplicationTypeDto.PRATIBHA_SAMMAN}));
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.APPROVE,approvedAmount:50} as any)).rejects.toThrow(BadRequestException);
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.CONSIDER_FOR_SAMMAN,reason:'yes'} as any)).resolves.toEqual({ok:true});
    await expect(s.review('a',{decision:HelpApplicationDecisionDto.NOT_SELECTED,reason:'no'} as any)).resolves.toEqual({ok:true});
    const appRef=refs.get('helpApplications:a') || collections.get('helpApplications').doc('a'); appRef.get.mockResolvedValue({exists:false});
    await expect(s.updateStatus('a','REJECTED',null,'reason')).rejects.toThrow(NotFoundException);
    appRef.get.mockResolvedValue({exists:true,data:()=>base({id:'a',type:HelpApplicationTypeDto.MEDICAL_HELP})});
    await expect(s.updateStatus('a','REJECTED',null,'reason',' note ')).resolves.toBeDefined();
    const causes=collections.get('causes'); causes.get.mockResolvedValue({empty:true,docs:[]});
    await expect(s.publishBeneficiary(base({type:HelpApplicationTypeDto.PRATIBHA_SAMMAN}))).rejects.toThrow(BadRequestException);
    causes.get.mockResolvedValue({empty:false,docs:[{id:'c',data:()=>({id:'c'})}]});
    const beneficiaries=collections.get('beneficiaries'); beneficiaries.get.mockResolvedValue({empty:true,docs:[]});
    await expect(s.publishBeneficiary(base({type:HelpApplicationTypeDto.PRATIBHA_SAMMAN,certificatePhotoMediaId:'c1',classStandard:'10',schoolInstituteName:'S',accomplishments:'A',adminNote:'N'}))).resolves.toBeUndefined();
    expect(deps.beneficiaries.syncBeneficiary).toHaveBeenCalled();
  });
});