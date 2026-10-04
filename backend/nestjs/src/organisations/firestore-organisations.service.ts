import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID as cryptoRandomUUID } from 'node:crypto';
import { FirebaseService } from '../firebase/firebase.service';

interface Translation {
  name?: string | null;
  description?: string | null;
}

interface OrganisationDocument {
  id: string;
  slug: string;
  logoUrl?: string | null;
  websiteUrl?: string | null;
  phone?: string | null;
  mobileNumber?: string | null;
  email?: string | null;
  address?: string | null;
  city?: string | null;
  state?: string | null;
  country?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  isActive: boolean;
  displayOrder: number;
  translations?: Record<string, Translation>;
  causeIds?: string[];
  media?: Array<{
    mediaId: string;
    purpose: string;
    displayOrder: number;
    isPrimary: boolean;
  }>;
}

interface CauseDocument {
  id: string;
  slug: string;
  isActive: boolean;
  displayOrder: number;
  translations?: Record<string, Translation>;
}

interface MediaDocument {
  id: string;
  storageKey: string;
  mimeType: string;
  width: number | null;
  height: number | null;
}

@Injectable()
export class FirestoreOrganisationsService {
  constructor(private readonly firebase: FirebaseService) {}

  async syncOrganisation(document: {
    id: string;
    slug: string;
    logoUrl: string | null;
    websiteUrl: string | null;
    phone: string | null;
    mobileNumber: string | null;
    email: string | null;
    address: string | null;
    city: string | null;
    state: string | null;
    country: string;
    latitude: number | null;
    longitude: number | null;
    isActive: boolean;
    displayOrder: number;
    translations: Record<string, Translation>;
    causeIds: string[];
    media: Array<{
      mediaId: string;
      purpose: string;
      displayOrder: number;
      isPrimary: boolean;
    }>;
    createdAt: Date;
    updatedAt: Date;
  }) {
    await this.firebase.db.collection('organisations').doc(document.id).set(document, { merge: true });
  }

  async removeOrganisation(id: string) {
    await this.firebase.db.collection('organisations').doc(id).delete();
  }

  async findAllForAdmin(){const snap=await this.firebase.db.collection('organisations').orderBy('displayOrder','asc').get();return snap.docs.map(d=>d.data());}
  async findOneForAdmin(id:string){const d=await this.firebase.db.collection('organisations').doc(id).get();if(!d.exists)throw new NotFoundException(`Organisation '${id}' not found`);return d.data();}
  async create(dto:any){const id=cryptoRandomUUID();const now=new Date();const slug=(dto.slug??dto.translations?.find((x:any)=>x.languageCode==='en')?.name??dto.translations?.[0]?.name??id).toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,'');const existing=await this.firebase.db.collection('organisations').where('slug','==',slug).limit(1).get();if(!existing.empty)throw new Error('Organisation slug already exists');const doc:any={id,slug,logoUrl:dto.logoUrl??null,websiteUrl:dto.websiteUrl??null,phone:dto.phone??null,mobileNumber:dto.mobileNumber??null,email:dto.email??null,address:dto.address??null,city:dto.city??null,state:dto.state??null,country:dto.country??'IN',latitude:dto.latitude??null,longitude:dto.longitude??null,isActive:dto.isActive??true,displayOrder:dto.displayOrder??0,translations:Object.fromEntries((dto.translations??[]).map((t:any)=>[t.languageCode,{name:t.name,description:t.description??null}])),causeIds:[],media:[],createdAt:now,updatedAt:now};await this.firebase.db.collection('organisations').doc(id).set(doc);return doc;}
  async update(id:string,dto:any){const ref=this.firebase.db.collection('organisations').doc(id);const snap=await ref.get();if(!snap.exists)throw new NotFoundException(`Organisation '${id}' not found`);const current=snap.data() as any;const next={...current,...dto,...(dto.translations?{translations:Object.fromEntries(dto.translations.map((t:any)=>[t.languageCode,{name:t.name,description:t.description??null}]))}:{}),updatedAt:new Date()};delete next.id;await ref.set(next,{merge:true});return {...next,id};}
  async updateCauses(id:string,causeIds:string[]){const ref=this.firebase.db.collection('organisations').doc(id);const snap=await ref.get();if(!snap.exists)throw new NotFoundException('Organisation not found.');await ref.update({causeIds:[...new Set(causeIds)],updatedAt:new Date()});return this.findOneForAdmin(id);}
  async listMedia(id:string){const x=await this.findOneForAdmin(id);const media=await this.getByIds<MediaDocument>('media',(x as any).media?.map((m:any)=>m.mediaId)??[]);const byId=new Map(media.map(m=>[m.id,m]));return ((x as any).media??[]).map((m:any)=>({...m,media:byId.get(m.mediaId)}));}
  async attachMedia(id:string,dto:any){const x=await this.findOneForAdmin(id) as any;const media=await this.firebase.db.collection('media').doc(dto.mediaId).get();if(!media.exists)throw new NotFoundException('Media not found.');const relations=[...(x.media??[])];if(relations.some((m:any)=>m.mediaId===dto.mediaId))throw new Error('Media is already attached to this organisation.');if(dto.isPrimary)relations.forEach((m:any)=>{if(m.purpose===(dto.purpose??'GALLERY'))m.isPrimary=false;});relations.push({mediaId:dto.mediaId,purpose:dto.purpose??'GALLERY',displayOrder:dto.displayOrder??0,isPrimary:dto.isPrimary??false});await this.firebase.db.collection('organisations').doc(id).update({media:relations,updatedAt:new Date()});return this.listMedia(id);}
  async updateMedia(id:string,mediaId:string,dto:any){const x=await this.findOneForAdmin(id) as any;const relations=(x.media??[]).map((m:any)=>m.mediaId===mediaId?{...m,...dto}:m);await this.firebase.db.collection('organisations').doc(id).update({media:relations,updatedAt:new Date()});return this.listMedia(id);}
  async removeMedia(id:string,mediaId:string){const x=await this.findOneForAdmin(id) as any;await this.firebase.db.collection('organisations').doc(id).update({media:(x.media??[]).filter((m:any)=>m.mediaId!==mediaId),updatedAt:new Date()});return{id,mediaId,deleted:true};}
  async removeOrDeactivate(id:string){const x=await this.findOneForAdmin(id) as any;const beneficiaries=await this.firebase.db.collection('beneficiaries').where('organisationId','==',id).get();const donations=await this.firebase.db.collection('donationAllocations').where('organisationId','==',id).get();if(!beneficiaries.empty||!donations.empty){await this.firebase.db.collection('organisations').doc(id).update({isActive:false,updatedAt:new Date()});return{id,deleted:false,deactivated:true};}await this.firebase.db.collection('organisations').doc(id).delete();return{id,deleted:true,deactivated:false};}
  async setActive(id:string,isActive:boolean){await this.findOneForAdmin(id);await this.firebase.db.collection('organisations').doc(id).update({isActive,updatedAt:new Date()});return this.findOneForAdmin(id);}
  async findAll(languageCode = 'en') {
    const snapshot = await this.firebase.db
      .collection('organisations')
      .where('isActive', '==', true)
      .orderBy('displayOrder', 'asc')
      .get();

    const organisations = snapshot.docs.map((doc) => doc.data() as OrganisationDocument);
    return this.withCauses(organisations, languageCode);
  }

  async findOne(slug: string, languageCode = 'en') {
    const snapshot = await this.firebase.db
      .collection('organisations')
      .where('slug', '==', slug)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new NotFoundException(`Organisation '${slug}' not found`);
    }

    const results = await this.withCauses(
      [snapshot.docs[0].data() as OrganisationDocument],
      languageCode,
    );
    return results[0];
  }

  private async withCauses(
    organisations: OrganisationDocument[],
    languageCode: string,
  ) {
    const causeIds = [...new Set(organisations.flatMap((item) => item.causeIds ?? []))];
    const causes = await this.getByIds<CauseDocument>('causes', causeIds);
    const causesById = new Map(causes.map((cause) => [cause.id, cause]));

    const mediaIds = [...new Set(
      organisations.flatMap((item) => (item.media ?? []).map((media) => media.mediaId)),
    )];
    const media = await this.getByIds<MediaDocument>('media', mediaIds);
    const mediaById = new Map(media.map((item) => [item.id, item]));

    return organisations.map((organisation) => {
      const relations = (organisation.media ?? [])
        .map((relation) => ({ ...relation, media: mediaById.get(relation.mediaId) }))
        .filter((relation) => relation.media);

      return {
        id: organisation.id,
        slug: organisation.slug,
        logoUrl: this.primaryMediaUrl(relations, 'LOGO') ?? organisation.logoUrl ?? null,
        gallery: this.galleryMedia(relations, 'GALLERY'),
        websiteUrl: organisation.websiteUrl ?? null,
        phone: organisation.phone ?? null,
        mobileNumber: organisation.mobileNumber ?? null,
        email: organisation.email ?? null,
        address: organisation.address ?? null,
        city: organisation.city ?? null,
        state: organisation.state ?? null,
        country: organisation.country ?? null,
        latitude: organisation.latitude ?? null,
        longitude: organisation.longitude ?? null,
        displayOrder: organisation.displayOrder,
        ...this.translation(organisation.translations, languageCode),
        causes: (organisation.causeIds ?? [])
          .map((id) => causesById.get(id))
          .filter((cause): cause is CauseDocument => Boolean(cause?.isActive))
          .sort((a, b) => a.displayOrder - b.displayOrder)
          .map((cause) => ({
            id: cause.id,
            slug: cause.slug,
            displayOrder: cause.displayOrder,
            ...this.translation(cause.translations, languageCode),
          })),
      };
    });
  }

  private async getByIds<T extends CauseDocument | MediaDocument>(
    collection: string,
    ids: string[],
  ): Promise<T[]> {
    if (!ids.length) return [];
    const uniqueIds = [...new Set(ids)];
    const chunks = Array.from(
      { length: Math.ceil(uniqueIds.length / 30) },
      (_, index) => uniqueIds.slice(index * 30, index * 30 + 30),
    );
    const snapshots = await Promise.all(
      chunks.map((chunk) =>
        this.firebase.db.getAll(
          ...chunk.map((id) => this.firebase.db.collection(collection).doc(id)),
        ),
      ),
    );
    const byId = new Map<string, T>();
    snapshots.flatMap((items) => items).forEach((doc) => {
      if (doc.exists) byId.set(doc.id, doc.data() as T);
    });
    return uniqueIds
      .map((id) => byId.get(id))
      .filter((item): item is T => Boolean(item));
  }

  private translation(
    translations: Record<string, Translation> | undefined,
    languageCode: string,
  ) {
    const translation = translations?.[languageCode] ?? translations?.en;
    return {
      name: translation?.name ?? null,
      description: translation?.description ?? null,
    };
  }

  private mediaUrl(media: MediaDocument) {
    const base = process.env.R2_PUBLIC_BASE_URL?.replace(/\/$/, '');
    return base ? `${base}/${media.storageKey}` : media.storageKey;
  }

  private primaryMediaUrl(relations: Array<{
    purpose: string;
    isPrimary: boolean;
    media?: MediaDocument;
  }>, purpose: string) {
    const relation =
      relations.find((item) => item.purpose === purpose && item.isPrimary) ??
      relations.find((item) => item.purpose === purpose);
    return relation?.media ? this.mediaUrl(relation.media) : null;
  }

  private galleryMedia(relations: Array<{
    purpose: string;
    displayOrder: number;
    media?: MediaDocument;
  }>, purpose: string) {
    return relations
      .filter((item) => item.purpose === purpose && item.media)
      .sort((a, b) => a.displayOrder - b.displayOrder)
      .map((item) => ({
        id: item.media!.id,
        url: this.mediaUrl(item.media!),
        mimeType: item.media!.mimeType,
        width: item.media!.width,
        height: item.media!.height,
      }));
  }
}
