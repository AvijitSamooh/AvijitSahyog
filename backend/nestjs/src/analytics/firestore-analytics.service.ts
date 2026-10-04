import { BadRequestException, Injectable, Optional } from '@nestjs/common';
import { Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service';
import { ANALYTICS_EVENT_NAMES, AnalyticsEventName } from './analytics.constants';

export const MAX_FIRESTORE_ANALYTICS_BATCH_SIZE = 50;

export type FirestoreAnalyticsInput = {
  clientId: string;
  sessionId: string;
  eventName: AnalyticsEventName;
  screenName?: string;
  interactionType?: string;
  target?: string;
  city?: string;
  language?: string;
  deviceType?: string;
};

@Injectable()
export class FirestoreAnalyticsService {
  constructor(private readonly firebase: FirebaseService) {}

  async trackBatch(inputs: FirestoreAnalyticsInput[]) {
    if (inputs.length === 0) return;
    if (inputs.length > MAX_FIRESTORE_ANALYTICS_BATCH_SIZE) {
      throw new BadRequestException(
        `Analytics batch cannot exceed ${MAX_FIRESTORE_ANALYTICS_BATCH_SIZE} events.`,
      );
    }

    for (const input of inputs) this.validate(input);

    const batch = this.firebase.db.batch();
    for (const input of inputs) {
      const ref = this.firebase.db.collection('analyticsEvents').doc();
      batch.set(ref, {
        id: ref.id,
        ...input,
        createdAt: Timestamp.now(),
      });
    }
    await batch.commit();
  }

  async summary(){const since=new Date(Date.now()-30*86400000);const s=await this.firebase.db.collection('analyticsEvents').where('createdAt','>=',since).get();const events=s.docs.map(d=>d.data());const users=new Set(events.map(e=>e.clientId));const sessions=new Set(events.map(e=>e.sessionId));const dau=new Set(events.filter(e=>new Date(e.createdAt?.toDate?.()??e.createdAt)>=new Date(Date.now()-86400000)).map(e=>e.clientId));const wau=new Set(events.filter(e=>new Date(e.createdAt?.toDate?.()??e.createdAt)>=new Date(Date.now()-7*86400000)).map(e=>e.clientId));return{periodDays:30,dau:dau.size,wau:wau.size,mau:users.size,sessions:sessions.size,screenViews:events.filter(e=>e.eventName==='screen_view').length,interactions:events.filter(e=>e.eventName==='ui_interaction').length,navigationEvents:events.filter(e=>e.eventName==='navigation_select').length};}
  async advancedSummary(){const since=new Date(Date.now()-30*86400000);const s=await this.firebase.db.collection('analyticsEvents').where('createdAt','>=',since).get();const events=s.docs.map(d=>d.data());const segment=(key:string)=>{const m=new Map<string,{u:Set<string>;e:number}>();for(const e of events){const v=String(e[key]??'unknown')||'unknown';const x=m.get(v)??{u:new Set<string>(),e:0};x.u.add(String(e.clientId));x.e++;m.set(v,x);}return [...m.entries()].map(([segment,x])=>({segment,users:x.u.size,events:x.e})).sort((a,b)=>b.users-a.users);};return{periodDays:30,retention:[],engagementCohorts:[],featureAdoption:[],segmentation:{city:segment('city'),language:segment('language'),device:segment('deviceType')},cohortUsers:new Set(events.map(e=>e.clientId)).size,mau:new Set(events.map(e=>e.clientId)).size,warehouse:{provider:'firestore',bigQueryReady:false,exportGrain:'analytics_event'}};}

  private validate(input: FirestoreAnalyticsInput) {
    if (!ANALYTICS_EVENT_NAMES.includes(input.eventName)) {
      throw new BadRequestException('Unsupported analytics event.');
    }
    if (
      !/^[a-f0-9-]{16,64}$/i.test(input.clientId) ||
      !/^[a-f0-9-]{16,64}$/i.test(input.sessionId)
    ) {
      throw new BadRequestException('Invalid analytics identifiers.');
    }
  }
}
