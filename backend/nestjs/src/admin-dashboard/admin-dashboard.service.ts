import { Injectable } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { FirestoreAnalyticsService } from '../analytics/firestore-analytics.service';
@Injectable()
export class AdminDashboardService {
 constructor(private readonly firebase:FirebaseService, private readonly analytics:FirestoreAnalyticsService){}
 async getSummary(){const count=async(c:string)=>{const [t,a]=await Promise.all([this.firebase.db.collection(c).count().get(),this.firebase.db.collection(c).where('isActive','==',true).count().get()]);return{total:t.data().count,active:a.data().count,inactive:t.data().count-a.data().count};};const [causes,organisations,beneficiaries]=await Promise.all([count('causes'),count('organisations'),count('beneficiaries')]);return{causes,organisations,beneficiaries};}
 async getAnalytics(){return this.analytics.summary();}
 async getAdvancedAnalytics(){return this.analytics.advancedSummary();}
}