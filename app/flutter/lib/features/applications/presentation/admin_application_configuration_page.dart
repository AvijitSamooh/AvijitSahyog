import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../../../l10n/app_localizations.dart';
import '../models/application_window.dart';
import '../providers/help_applications_providers.dart';

class AdminApplicationConfigurationPage extends ConsumerStatefulWidget {
  const AdminApplicationConfigurationPage({super.key});
  @override ConsumerState<AdminApplicationConfigurationPage> createState()=>_AdminApplicationConfigurationPageState();
}
class _AdminApplicationConfigurationPageState extends ConsumerState<AdminApplicationConfigurationPage>{
  Future<void> _start(String type) async {
    final l10n=AppLocalizations.of(context)!;final now=DateTime.now();
    final windows=ref.read(applicationWindowsProvider).valueOrNull??const <ApplicationWindow>[];
    final current=windows.where((w)=>w.type==type).firstOrNull;
    final date=await showDatePicker(context:context,initialDate:current?.startsAt.toLocal()??now,firstDate:DateTime(now.year,now.month,now.day),lastDate:DateTime(now.year+2,12,31),helpText:l10n.applicationStartDate);
    if(date==null||!mounted)return;
    final time=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(current?.startsAt.toLocal()??now),helpText:l10n.applicationStartTime);
    if(time==null||!mounted)return;
    DateTime? end;DateTime? event;
    final starts=DateTime(date.year,date.month,date.day,time.hour,time.minute);
    if(type=='PRATIBHA_SAMMAN'){
      final endDate=await showDatePicker(context:context,initialDate:current?.registrationEndsAt?.toLocal()??starts.add(const Duration(days:7)),firstDate:date,lastDate:DateTime(now.year+2,12,31),helpText:l10n.registrationLastDate);
      if(endDate==null||!mounted)return;end=DateTime(endDate.year,endDate.month,endDate.day,23,59,59);
      event=await showDatePicker(context:context,initialDate:current?.eventAt?.toLocal()??DateTime(2026,10,25),firstDate:date,lastDate:DateTime(now.year+2,12,31),helpText:l10n.eventDate);
      if(event==null||!mounted)return;event=DateTime(event.year,event.month,event.day);
    }
    try{
      await ref.read(helpApplicationsRepositoryProvider).startApplicationWindow(type:type,startsAt:starts,registrationEndsAt:end,eventAt:event);
      ref.invalidate(applicationWindowsProvider);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.applicationWindowSaved)));
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.applicationWindowSaveFailed)));}
  }
  Future<void> _close(String type) async {
    final l10n=AppLocalizations.of(context)!;
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:Text(l10n.applicationWindowCloseTitle),content:Text(l10n.applicationWindowCloseConfirmation),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(l10n.cancel)),FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(l10n.closeApplications))]));
    if(ok!=true||!mounted)return;
    try{await ref.read(helpApplicationsRepositoryProvider).closeApplicationWindow(type);ref.invalidate(applicationWindowsProvider);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.applicationWindowClosed)));}
    catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.applicationWindowSaveFailed)));}
  }
  @override Widget build(BuildContext context){
    final l10n=AppLocalizations.of(context)!;final windows=ref.watch(applicationWindowsProvider);
    return AppPageScaffold(title:Text(l10n.applicationConfiguration),body:ListView(padding:const EdgeInsets.all(12),children:[
      Text(l10n.applicationWindowManagement,key:const ValueKey('application_window_management'),style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:4),Text(l10n.applicationWindowManagementSubtitle),const SizedBox(height:12),
      windows.when(loading:()=>const LinearProgressIndicator(),error:(_,_)=>Text(l10n.applicationAvailabilityLoadError),data:(items)=>Column(children:['EDUCATION_ASSISTANCE','MEDICAL_HELP','PRATIBHA_SAMMAN'].map((type){
        final current=items.where((w)=>w.type==type).firstOrNull;final status=current?.status??ApplicationWindowStatus.closed;
        final text=switch(status){ApplicationWindowStatus.scheduled=>l10n.applicationAcceptingStartsAt(_date(context,current!.startsAt)),ApplicationWindowStatus.open=>l10n.applicationAcceptingNow,ApplicationWindowStatus.closed=>l10n.applicationAcceptingClosed};
        return Card(child:ListTile(title:Text(_typeLabel(l10n,type)),subtitle:Text(text),trailing:Wrap(children:[IconButton(key:ValueKey('application_window_start_$type'),onPressed:()=>_start(type),icon:const Icon(Icons.schedule_rounded)),if(current!=null&&status!=ApplicationWindowStatus.closed)IconButton(key:ValueKey('application_window_close_$type'),onPressed:()=>_close(type),icon:const Icon(Icons.stop_circle_outlined))])));
      }).toList())),
      const SizedBox(height:20),const _ApplicationRulesConfiguration(),
    ]));
  }
}
class _ApplicationRulesConfiguration extends ConsumerStatefulWidget{const _ApplicationRulesConfiguration();@override ConsumerState<_ApplicationRulesConfiguration> createState()=>_ApplicationRulesConfigurationState();}
class _ApplicationRulesConfigurationState extends ConsumerState<_ApplicationRulesConfiguration>{
  String _type='PRATIBHA_SAMMAN';List<Map<String,dynamic>> _rules=const[];bool _loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{setState(()=>_loading=true);try{final r=await ref.read(helpApplicationsRepositoryProvider).adminApplicationRules(_type);if(mounted)setState((){_rules=r.where((x)=>x['isActive']!=false).toList(growable:false);_loading=false;});}catch(_){if(mounted)setState(()=>_loading=false);}}
  Future<void> _delete(Map<String,dynamic> rule) async {
    final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete rule?'),content:const Text('This rule will no longer be shown to applicants.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]));
    if(confirmed!=true)return;
    try{await ref.read(helpApplicationsRepositoryProvider).deleteAdminApplicationRule(rule['id'] as String);await _load();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Unable to delete rule.')));}
  }
  Future<void> _edit([Map<String,dynamic>? rule])async{
    final l10n=AppLocalizations.of(context)!;final t=<String,TextEditingController>{};
    for(final lang in ['en','hi','mr','gu']){String value='';for(final raw in (rule?['translations'] as List<dynamic>? ?? const [])){final m=raw as Map<String,dynamic>;if(m['language']==lang)value=m['text']?.toString()??'';}t[lang]=TextEditingController(text:value);}
    final order=TextEditingController(text:(rule?['displayOrder']??_rules.length+1).toString());var active=rule?['isActive'] as bool? ?? true;
    final save=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(title:Text(rule==null?l10n.addApplicationRule:l10n.editApplicationRule),content:SingleChildScrollView(child:Column(children:[TextField(controller:order,decoration:InputDecoration(labelText:l10n.ruleDisplayOrder)),...t.entries.map((e)=>TextField(controller:e.value,maxLines:3,decoration:InputDecoration(labelText:e.key.toUpperCase()))),SwitchListTile(value:active,onChanged:(v)=>setDialog(()=>active=v),title:Text(l10n.ruleActive))])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(l10n.cancel)),FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(l10n.saveRule))])));
    if(save!=true){ for(final c in t.values){ c.dispose(); } order.dispose(); return; }
    final values=t.map((k,v)=>MapEntry(k,v.text.trim()));if(values.values.any((v)=>v.isEmpty)){ for(final c in t.values){ c.dispose(); } order.dispose(); if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.allRuleTranslationsRequired))); } return; }
    final payload={'type':_type,'displayOrder':int.tryParse(order.text)??_rules.length+1,'isActive':active,'translations':values.entries.map((e)=>{'language':e.key,'text':e.value}).toList()};
    try{ final repo=ref.read(helpApplicationsRepositoryProvider); if(rule==null){ await repo.createAdminApplicationRule(payload); } else { final p=Map<String,dynamic>.from(payload)..remove('type'); await repo.updateAdminApplicationRule(rule['id'] as String,p); } await _load(); }catch(_){ if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(l10n.ruleActionFailed))); } }finally{ for(final c in t.values){ c.dispose(); } order.dispose(); }
  }
  @override Widget build(BuildContext context){final l10n=AppLocalizations.of(context)!;return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l10n.adminApplicationRules,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:4),Text(l10n.adminApplicationRulesSubtitle),DropdownButtonFormField<String>(initialValue:_type,items:['EDUCATION_ASSISTANCE','MEDICAL_HELP','PRATIBHA_SAMMAN'].map((t)=>DropdownMenuItem(value:t,child:Text(_typeLabel(l10n,t)))).toList(),onChanged:(v){if(v==null)return;setState(()=>_type=v);_load();}),Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:_edit,icon:const Icon(Icons.add),label:Text(l10n.addApplicationRule))),if(_loading)const LinearProgressIndicator(),if(!_loading&&_rules.isEmpty)Text(l10n.noApplicationRules),if(!_loading)..._rules.map((rule)=>ListTile(title:Text(((rule['translations'] as List<dynamic>? ?? const []).cast<Map<String,dynamic>>().firstWhere((x)=>x['language']=='en',orElse:()=>{'text':''})['text']??'').toString()),trailing:Wrap(children:[IconButton(onPressed:()=>_edit(rule),icon:const Icon(Icons.edit_outlined)),IconButton(onPressed:()=>_delete(rule),icon:const Icon(Icons.delete_outline),tooltip:'Delete')])))])));}
}
String _typeLabel(AppLocalizations l10n,String type)=>switch(type){'MEDICAL_HELP'=>l10n.medicalHelp,'PRATIBHA_SAMMAN'=>l10n.pratibhaSamman,_=>l10n.educationHelp};
String _date(BuildContext context,DateTime value)=>MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
