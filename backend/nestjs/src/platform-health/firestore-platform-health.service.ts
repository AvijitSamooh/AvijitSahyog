import { Injectable } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service';
import type { PlatformHealthEventType, RecordHealthEventInput } from './platform-health.service';

@Injectable()
export class FirestorePlatformHealthService {
  constructor(private readonly firebase: FirebaseService) {}

  async ping(){ await this.firebase.db.collection('platformSettings').doc('downtime').get(); }

  async listRecent(days:number){ const since=new Date(Date.now()-days*86400000); const snap=await this.firebase.db.collection('platformHealthEvents').where('createdAt','>=',since).orderBy('createdAt','desc').limit(5000).get(); return snap.docs.map(d=>{const x=d.data(); return {id:d.id,type:String(x.type??''),statusCode:x.statusCode==null?null:Number(x.statusCode),route:x.route==null?null:String(x.route),method:x.method==null?null:String(x.method),message:x.message==null?null:String(x.message),createdAt:x.createdAt?.toDate?.()??new Date(String(x.createdAt))};}); }

  async recordEvent(input: RecordHealthEventInput) {
    const ref = this.firebase.db.collection('platformHealthEvents').doc();
    await ref.set({
      id: ref.id,
      type: input.type,
      statusCode: input.statusCode ?? null,
      route: input.route ? input.route.split('?')[0].slice(0, 200) : null,
      method: input.method ?? null,
      message: input.message ? input.message.replace(/\s+/g, ' ').slice(0, 500) : null,
      metadata: input.metadata ?? null,
      createdAt: Timestamp.now(),
    });
  }
}
