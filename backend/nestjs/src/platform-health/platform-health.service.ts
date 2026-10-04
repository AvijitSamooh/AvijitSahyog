import { Injectable } from '@nestjs/common';
import { FirestorePlatformHealthService } from './firestore-platform-health.service';
export type PlatformHealthEventType='HTTP_ERROR'|'AUTH_FAILURE'|'UPLOAD_FAILURE'|'APP_ERROR'|'APP_CRASH';
export type RecordHealthEventInput={type:PlatformHealthEventType;statusCode?:number;route?:string;method?:string;message?:string;metadata?:Record<string,unknown>};
@Injectable()
export class PlatformHealthService {
 private readonly startedAt=new Date();
 constructor(private readonly firestore:FirestorePlatformHealthService){}
 async recordEvent(input:RecordHealthEventInput){try{await this.firestore.recordEvent(input);}catch{}}
 async getSummary(){const now=Date.now();const events=await this.firestore.listRecent(7);const recent=events.filter((e:any)=>e.createdAt.getTime()>=now-86400000);const count=(a:any[],t:string)=>a.filter(e=>e.type===t).length;const byType=Object.fromEntries([...new Set(events.map((e:any)=>e.type))].map(t=>[t,count(events,t)]));return{status:'healthy',api:{status:'ok',uptimeSeconds:Math.floor((now-this.startedAt.getTime())/1000)},database:await this.checkDatabase(),deployment:{environment:process.env.NODE_ENV??'unknown',version:process.env.APP_VERSION??'unknown',deploymentId:process.env.DEPLOYMENT_ID??'unknown',gitSha:process.env.GIT_SHA??'unknown',deployedAt:process.env.DEPLOYED_AT??null},errors24h:count(recent,'HTTP_ERROR'),authFailures24h:count(recent,'AUTH_FAILURE'),uploadFailures24h:count(recent,'UPLOAD_FAILURE'),appErrors24h:count(recent,'APP_ERROR'),crashes24h:count(recent,'APP_CRASH'),last7Days:byType,recentEvents:events.slice(0,25).map((e:any)=>({...e,createdAt:e.createdAt.toISOString()}))};}
 async checkDatabase(){try{await this.firestore.ping();return'ok' as const;}catch{return'error' as const;}}
}