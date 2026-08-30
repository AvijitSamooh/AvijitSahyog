import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../causes/models/organisation.dart';
import '../models/create_donation.dart';
import '../providers/donation_providers.dart';

class DonationPage extends ConsumerStatefulWidget {
  const DonationPage({super.key, required this.causeId, required this.causeName, required this.organisations});
  final String causeId;
  final String causeName;
  final List<Organisation> organisations;
  @override ConsumerState<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends ConsumerState<DonationPage> {
  final _amountController = TextEditingController();
  int? _selectedAmount;
  bool _submitting = false;
  static const _amounts = [100, 500, 1000, 2000];

  @override void initState() { super.initState(); }
  @override void dispose() { _amountController.dispose(); super.dispose(); }
  double get _totalAmount => double.tryParse(_amountController.text.trim()) ?? 0;

  void _selectAmount(int amount) { setState(() { _selectedAmount = amount; _amountController.text = amount.toString(); }); }
  void _onTotalChanged(String value) { final parsed = double.tryParse(value.trim()); setState(() { _selectedAmount = parsed != null && _amounts.contains(parsed.toInt()) ? parsed.toInt() : null; }); }

  Future<void> _submit() async { final l10n = AppLocalizations.of(context)!; final total = _totalAmount; if (total <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.donationInvalidAmount))); return; } final allocations = <CreateDonationAllocation>[]; setState(() => _submitting = true); try { await ref.read(donationRepositoryProvider).createDonation(CreateDonation(amount: total.toStringAsFixed(2), allocations: allocations)); if (!mounted) return; await showDialog<void>(context: context, builder: (context) => AlertDialog(title: Text(l10n.donationCreatedTitle), content: Text(l10n.donationCreatedMessage), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.done))])); if (mounted) Navigator.pop(context); } catch (_) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.donationCreateError))); } finally { if (mounted) setState(() => _submitting = false); } }

  @override Widget build(BuildContext context) { final l10n = AppLocalizations.of(context)!; final theme = Theme.of(context); return Scaffold(appBar: AppBar(title: Text(l10n.donateTitle)), body: ListView(padding: const EdgeInsets.fromLTRB(20,20,20,32), children: [Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors: [Color(0xFF6E1A14),Color(0xFF4C120D)]),borderRadius: BorderRadius.circular(24),border: Border.all(color: const Color(0xFFC89B3C))), child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [const Text('दान',style: TextStyle(color: Color(0xFFF5A623),fontWeight: FontWeight.w700,fontSize: 14)),const SizedBox(height:8),Text(widget.causeName,style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white,fontSize:25)),const SizedBox(height:6),Text('अपनी पसंद की राशि चुनें और इस उद्देश्य के लिए सहयोग करें।',style: TextStyle(color: Colors.white.withValues(alpha:0.82),fontSize:14))])),const SizedBox(height:28),Text(l10n.chooseAmount,style: theme.textTheme.titleLarge),const SizedBox(height:14),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:_amounts.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:2.5),itemBuilder:(context,index){final amount=_amounts[index];final selected=_selectedAmount==amount;return OutlinedButton(key:ValueKey('donation_amount_$amount'),onPressed:()=>_selectAmount(amount),style:OutlinedButton.styleFrom(backgroundColor:selected?const Color(0xFFFCE8C9):Colors.white,foregroundColor:const Color(0xFF6E1A14),side:BorderSide(color:selected?const Color(0xFFC89B3C):const Color(0xFFE8DCC8),width:selected?1.5:1),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),child:Text('₹ $amount'));}),const SizedBox(height:22),TextField(key:const ValueKey('donation_amount_input'),controller:_amountController,keyboardType:const TextInputType.numberWithOptions(decimal:true),onChanged:_onTotalChanged,decoration:InputDecoration(labelText:l10n.customAmount,prefixText:'₹ ',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)))),const SizedBox(height:24),if(_totalAmount>0)Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFFFFF8ED),borderRadius:BorderRadius.circular(16)),child:const Text('Your contribution will support this cause. You can explore affiliated organisations and beneficiaries separately.')),const SizedBox(height:18),FilledButton.icon(key:const ValueKey('donation_submit'),onPressed:_submitting||_totalAmount<=0?null:_submit,icon:_submitting?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.favorite_rounded),label:Text(l10n.donateNow)),const SizedBox(height:12),Text(l10n.donationPaymentLater,textAlign:TextAlign.center,style:theme.textTheme.bodySmall)])); }
}
