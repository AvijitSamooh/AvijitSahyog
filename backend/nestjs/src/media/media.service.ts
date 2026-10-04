import { BadRequestException, Injectable, NotFoundException, InternalServerErrorException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import sharp from 'sharp';
import { FirestoreMediaService } from './firestore-media.service';
import { FirebaseService } from '../firebase/firebase.service';
import { R2StorageService } from './r2-storage.service';

const ALLOWED_IMAGE_FORMATS = new Set(['jpeg','png','webp']);
const MAX_UPLOAD_SIZE = 10 * 1024 * 1024;
const MAX_DIMENSION = 1600;
const MAX_PROCESSED_SIZE = 1.5 * 1024 * 1024;

@Injectable()
export class MediaService {
  constructor(private readonly r2:R2StorageService, private readonly firestore:FirestoreMediaService, private readonly firebase:FirebaseService) {}

  async uploadImage(file:Express.Multer.File,folder='uploads',uploadedById?:string){
    if(!file)throw new BadRequestException('Image file is required.');
    if(file.size>MAX_UPLOAD_SIZE)throw new BadRequestException('Image must be 10 MB or smaller.');
    try{
      let meta: sharp.Metadata;
      try {
        meta = await sharp(file.buffer).metadata();
      } catch {
        throw new BadRequestException('The uploaded file is not a valid supported image.');
      }
      if(!meta.format||!ALLOWED_IMAGE_FORMATS.has(meta.format))throw new BadRequestException('Only JPEG, PNG, and WebP images are allowed.');
      let processed=await this.encode(file.buffer,MAX_DIMENSION,82);
      for(const quality of [76,72,68]){if(processed.length<=MAX_PROCESSED_SIZE)break;processed=await this.encode(file.buffer,MAX_DIMENSION,quality);}
      if(processed.length>MAX_PROCESSED_SIZE)processed=await this.encode(file.buffer,1400,65);
      if(processed.length>MAX_PROCESSED_SIZE)throw new BadRequestException('Image could not be optimized below the 1.5 MB storage limit. Please choose a smaller image.');
      const outputMeta=await sharp(processed).metadata(); const id=randomUUID(); const key=`${folder}/${id}.webp`;
      await this.r2.upload(key,processed,'image/webp');
      try{
        const now=new Date();
        const result=await this.firestore.upsert({id,uploadedById:uploadedById??null,storageKey:key,mimeType:'image/webp',fileSize:processed.length,width:outputMeta.width??null,height:outputMeta.height??null,createdAt:now,updatedAt:now});
        return result;
      }catch(error){await this.r2.delete(key).catch(()=>undefined);throw error;}
    }catch(error){if(error instanceof BadRequestException)throw error;if(error instanceof InternalServerErrorException)return error;throw new InternalServerErrorException('Unable to process and upload image.');}
  }

  async downloadImage(storageKey:string){return this.r2.download(storageKey);}

  async deleteUserImage(id:string,uploadedById:string){
    const media=await this.firestore.getById(id);
    if(media.uploadedById!==uploadedById)throw new NotFoundException('Image not found.');
    const refs=await this.referenceCount(id);
    if(refs>0)throw new BadRequestException('This image is still attached to an application and cannot be deleted.');
    await this.r2.delete(media.storageKey); await this.firestore.delete(id); return{id,deleted:true};
  }

  private async referenceCount(id:string){
    const checks=await Promise.all([
      this.firebaseCount('organisations',id),this.firebaseCount('beneficiaries',id),this.firebaseCount('helpApplications',id),
    ]);
    return checks.reduce((a,b)=>a+b,0);
  }
  private async firebaseCount(collection:string,id:string){
    const snap=await this.firebase.db.collection(collection).where('media','array-contains',id).count().get().catch(()=>null);
    if(snap)return snap.data().count;
    const direct=await this.firestore['firebase'].db.collection(collection).get();
    return direct.docs.filter(d=>JSON.stringify(d.data()).includes(id)).length;
  }
  private async encode(buffer:Buffer,width:number,quality:number){return sharp(buffer).rotate().resize({width,height:width,fit:'inside',withoutEnlargement:true}).webp({quality}).toBuffer();}
}
