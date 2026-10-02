import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/help_applications_providers.dart';

class AdminApplicationsPage extends ConsumerStatefulWidget {
  const AdminApplicationsPage({super.key});
  @override ConsumerState<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}
class _AdminApplicationsPageState extends ConsumerState<AdminApplicationsPage> {
  String? _type; String? _status; bool _loading = true; String? _error; List<Map<String,dynamic>> _items = const []; Map<String,dynamic>? _summary; bool _topOnly = false; int _topLimit = 50;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    if(mounted)setState((){_loading=true;_error=null;});
    try{final results=await Future.wait([ref.read(helpApplicationsRepositoryProvider).adminList(type:_type,status:_status),ref.read(helpApplicationsRepositoryProvider).adminSummary(type:_type)]);if(mounted)setState((){_items=results[0] as List<Map<String,dynamic>>;_summary=results[1] as Map<String,dynamic>;_loading=false;});}
    catch(e){if(mounted)setState((){_error=e.toString();_loading=false;});}
  }
  Future<void> _vote(Map<String,dynamic> item) async {
    final l10n=AppLocalizations.of(context)!;
    final score=await showDialog<int>(context:context,builder:(_)=>SimpleDialog(title:Text(l10n.voteScore),children:List.generate(5,(i)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,i+1),child:Text((i+1).toString())))));
    if(score==null||!mounted)return;
    try{await ref.read(helpApplicationsRepositoryProvider).vote(item['id'] as String,score);await _load();}
    catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.applicationActionFailed)));}
  }
  Future<void> _review(Map<String,dynamic> item) async {
    final l10n=AppLocalizations.of(context)!; final isSamman=item['type']=='PRATIBHA_SAMMAN';
    final decision=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:Text(l10n.reviewDecision),children:[
      if(!isSamman)SimpleDialogOption(onPressed:()=>Navigator.pop(context,'APPROVE'),child:Text(l10n.approveForDonation)),
      SimpleDialogOption(onPressed:()=>Navigator.pop(context,'REJECT'),child:Text(l10n.rejectApplication)),
      SimpleDialogOption(onPressed:()=>Navigator.pop(context,'CLARIFICATION_REQUIRED'),child:Text(l10n.requestClarification)),
      if(isSamman)...[SimpleDialogOption(onPressed:()=>Navigator.pop(context,'CONSIDER_FOR_SAMMAN'),child:Text(l10n.considerForSamman)),SimpleDialogOption(onPressed:()=>Navigator.pop(context,'NOT_SELECTED'),child:Text(l10n.notSelected))],
    ]));
    if(decision==null||!mounted)return;
    double? amount; String? reason;
    if(decision=='APPROVE'){
      final controller=TextEditingController();
      amount=double.tryParse(await showDialog<String>(context:context,builder:(_)=>AlertDialog(title:Text(l10n.approvedAmount),content:TextField(controller:controller,keyboardType:const TextInputType.numberWithOptions(decimal:true)),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(l10n.cancel)),FilledButton(onPressed:()=>Navigator.pop(context,controller.text),child:Text(l10n.saveReview))]))??'');
      controller.dispose();
    }else if(decision=='REJECT'||decision=='CLARIFICATION_REQUIRED'){
      final controller=TextEditingController();
      reason=await showDialog<String>(context:context,builder:(_)=>AlertDialog(title:Text(decision=='REJECT'?l10n.rejectionReason:l10n.clarification),content:TextField(controller:controller,minLines:3,maxLines:6),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(l10n.cancel)),FilledButton(onPressed:()=>Navigator.pop(context,controller.text),child:Text(l10n.saveReview))]));
      controller.dispose();
    }
    try{
      await ref.read(helpApplicationsRepositoryProvider).review(item['id'] as String,{'decision':decision,'approvedAmount':?amount,'reason':?(reason?.trim().isNotEmpty==true?reason!.trim():null)});
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.reviewSaved)));await _load();}
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.applicationActionFailed)));}
  }
  Future<void> _photoManifest() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final items = await ref.read(helpApplicationsRepositoryProvider).photoManifest(type: _type, status: _status);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.applicationPhotoManifest),
          content: SizedBox(
            width: 700,
            child: items.isEmpty
                ? Text(l10n.noApplicationPhotos)
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final photo = item['facePhoto'] as Map<String, dynamic>?;
                      final url = photo?['url']?.toString();
                      return ListTile(
                        leading: url == null ? const Icon(Icons.person_outline) : CircleAvatar(backgroundImage: NetworkImage(url)),
                        title: Text(item['name']?.toString() ?? l10n.fullNameRequired),
                        subtitle: SelectableText(url ?? ''),
                      );
                    },
                  ),
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))],
        ),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.applicationActionFailed)));
    }
  }
  List<Map<String,dynamic>> get _visibleItems => _topOnly ? _items.take(_topLimit).toList(growable: false) : _items;

  @override Widget build(BuildContext context){
    final l10n=AppLocalizations.of(context)!;
    return AppPageScaffold(title:Text(l10n.adminApplications),body:RefreshIndicator(onRefresh:_load,child:CustomScrollView(physics:const AlwaysScrollableScrollPhysics(),slivers:[
      SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
        if(_summary!=null)
          Wrap(spacing:8,runSpacing:8,children:[
            _summaryCard(context,l10n.reviewSummary,(_summary!['total']??0).toString(),Icons.inbox_outlined),
            _summaryCard(context,l10n.needsReview,(_summary!['needsReview']??0).toString(),Icons.pending_actions_outlined),
            _summaryCard(context,l10n.selectedApplications,(_summary!['selected']??0).toString(),Icons.check_circle_outline),
            _summaryCard(context,l10n.rejectedApplications,(_summary!['rejected']??0).toString(),Icons.cancel_outlined),
          ]),
        const SizedBox(height:10),
        Row(children:[
          Expanded(child:Text(l10n.shortlistByPercentage,style:Theme.of(context).textTheme.titleSmall)),
          FilterChip(selected:_topOnly,label:Text(l10n.shortlistByPercentage + ' 50'),onSelected:(value){setState(()=>_topOnly=value);}),
        ]),
        const SizedBox(height:8),
        Wrap(spacing:8,runSpacing:8,children:[
          FilterChip(label:Text(l10n.applicationsTitle),selected:_type==null,onSelected:(_){setState(()=>_type=null);_load();}),
          FilterChip(label:Text(l10n.educationHelp),selected:_type=='EDUCATION_ASSISTANCE',onSelected:(_){setState(()=>_type='EDUCATION_ASSISTANCE');_load();}),
          FilterChip(label:Text(l10n.medicalHelp),selected:_type=='MEDICAL_HELP',onSelected:(_){setState(()=>_type='MEDICAL_HELP');_load();}),
          FilterChip(label:Text(l10n.pratibhaSamman),selected:_type=='PRATIBHA_SAMMAN',onSelected:(_){setState(()=>_type='PRATIBHA_SAMMAN');_load();}),
        ]),
        const SizedBox(height:8),
        DropdownButtonFormField<String>(initialValue:_status,decoration:InputDecoration(labelText:l10n.applicationStatus),items:['SUBMITTED','UNDER_REVIEW','CLARIFICATION_REQUIRED','APPROVED_FOR_DONATION','REJECTED','CONSIDERED_FOR_SAMMAN','NOT_SELECTED'].map((s)=>DropdownMenuItem(value:s,child:Text(_statusLabel(l10n,s)))).toList(),onChanged:(v){setState(()=>_status=v);_load();}),
        const SizedBox(height:8),
        Align(alignment:Alignment.centerRight,child:OutlinedButton.icon(key:const ValueKey('admin_application_photo_manifest'),onPressed:_photoManifest,icon:const Icon(Icons.photo_library_outlined),label:Text(l10n.applicationPhotoManifest))),
      ]))),
      if(_loading)const SliverFillRemaining(hasScrollBody:false,child:Center(child:CircularProgressIndicator()))
      else if(_error!=null)SliverFillRemaining(hasScrollBody:false,child:Center(child:Text(_error!)))
      else if(_visibleItems.isEmpty)SliverFillRemaining(hasScrollBody:false,child:Center(child:Text(l10n.noApplications)))
      else SliverPadding(padding:const EdgeInsets.fromLTRB(12,4,12,24),sliver:SliverList(delegate:SliverChildBuilderDelegate((context,index){
        final item=_visibleItems[index];final face=item['facePhoto'] as Map<String,dynamic>?;final url=face?['url']?.toString();final name=(item['applicantName']??item['applicant']?['displayName']??item['applicant']?['email']??l10n.fullNameRequired).toString();final status=item['status'] as String? ?? '';
        return Card(child:ListTile(contentPadding:const EdgeInsets.all(10),leading:url==null?const CircleAvatar(child:Icon(Icons.person_outline)):CircleAvatar(radius:30,backgroundImage:NetworkImage(url)),title:Text(name),subtitle:Text('${_typeLabel(l10n,item['type'] as String)} • ${_statusLabel(l10n,status)} • ${item['overallPercentage'] ?? '—'}%'),onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>AdminApplicationDetailsPage(item:item))),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='vote')_vote(item);if(v=='review')_review(item);},itemBuilder:(_)=>[PopupMenuItem(value:'vote',child:Text(l10n.vote)),PopupMenuItem(value:'review',child:Text(l10n.reviewDecision))])));
      },childCount:_visibleItems.length))),
    ])));
  }
}

Widget _summaryCard(BuildContext context, String label, String value, IconData icon) => SizedBox(width:170,child:Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[Icon(icon),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:Theme.of(context).textTheme.titleLarge),Text(label,overflow:TextOverflow.ellipsis)]))])));

class AdminApplicationDetailsPage extends StatelessWidget {
  const AdminApplicationDetailsPage({super.key,required this.item});
  final Map<String,dynamic> item;
  @override Widget build(BuildContext context){
    final l10n=AppLocalizations.of(context)!;final face=item['facePhoto'] as Map<String,dynamic>?;final cert=item['certificatePhoto'] as Map<String,dynamic>?;final media=(item['media'] as List<dynamic>? ?? const []).cast<Map<String,dynamic>>();
    final images=<Map<String,dynamic>>[?face,if(cert!=null&&cert['id']!=face?['id'])cert,...media];
    Widget field(String label,dynamic value){final s=value?.toString().trim()??'';if(s.isEmpty||s=='null')return const SizedBox.shrink();return Padding(padding:const EdgeInsets.only(bottom:8),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:145,child:Text(label,style:Theme.of(context).textTheme.labelLarge)),Expanded(child:SelectableText(s))]));}
    return AppPageScaffold(title:Text(l10n.adminApplications),body:ListView(padding:const EdgeInsets.all(16),children:[
      if(face?['url']!=null)ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.network(face!['url'].toString(),height:240,fit:BoxFit.cover)),
      const SizedBox(height:16),Text(item['applicantName']?.toString()??'',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:8),
      field(l10n.applicationStatus,_statusLabel(l10n,item['status'] as String? ?? '')),field(l10n.overallPercentage,item['overallPercentage']==null?null:'${item['overallPercentage']}%'),field(l10n.requestedAmount,item['requestedAmount']==null?null:'₹${item['requestedAmount']}'),field(l10n.approvedAmount,item['approvedAmount']==null?null:'₹${item['approvedAmount']}'),
      field(l10n.mobileNumberRequired,item['mobileNumber']),field(l10n.emailOptional,item['email']),field(l10n.addressRequired,item['address']),field(l10n.cityRequired,item['city']),field(l10n.stateRequired,item['state']),field(l10n.pincodeRequired,item['pincode']),
      field(l10n.motherNameRequired,item['motherName']),field(l10n.fatherNameRequired,item['fatherName']),field(l10n.dateOfBirthRequired,item['dateOfBirth']),field(l10n.classStandardRequired,item['classStandard']),field(l10n.schoolInstituteRequired,item['schoolInstituteName']),field(l10n.otherAccomplishmentsOptional,item['accomplishments']),field(l10n.explainNeed,item['clarification']),field(l10n.rejectionReason,item['rejectionReason']),
      const SizedBox(height:16),Text(l10n.supportingDocuments,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:10),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:images.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(_,i){final url=images[i]['url']?.toString();return InkWell(onTap:url==null?null:()=>showDialog<void>(context:context,builder:(_)=>Dialog(child:InteractiveViewer(child:Image.network(url)))),child:ClipRRect(borderRadius:BorderRadius.circular(10),child:url==null?const Icon(Icons.broken_image_outlined):Image.network(url,fit:BoxFit.cover)));}),
    ]));
  }
}
String _typeLabel(AppLocalizations l10n,String type)=>switch(type){'MEDICAL_HELP'=>l10n.medicalHelp,'PRATIBHA_SAMMAN'=>l10n.pratibhaSamman,_=>l10n.educationHelp};
String _statusLabel(AppLocalizations l10n,String status)=>switch(status){'SUBMITTED'=>l10n.statusSubmitted,'UNDER_REVIEW'=>l10n.statusUnderReview,'CLARIFICATION_REQUIRED'=>l10n.statusClarification,'APPROVED_FOR_DONATION'=>l10n.statusApproved,'REJECTED'=>l10n.statusRejected,'CONSIDERED_FOR_SAMMAN'=>l10n.statusConsidered,_=>l10n.statusNotSelected};
