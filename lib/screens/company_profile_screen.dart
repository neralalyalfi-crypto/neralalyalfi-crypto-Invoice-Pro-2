import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});
  @override State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}
class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final name=TextEditingController(),gstin=TextEditingController(),address=TextEditingController(),phone=TextEditingController(),email=TextEditingController();
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final c=await DatabaseService.instance.getCompany();
    name.text=c['name']??'';gstin.text=c['gstin']??'';address.text=c['address']??'';phone.text=c['phone']??'';email.text=c['email']??'';
    if(mounted)setState((){});
  }
  Future<void> _save() async {
    if(name.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Business name is required.')));return;}
    await DatabaseService.instance.saveCompany({'name':name.text.trim(),'gstin':gstin.text.trim(),'address':address.text.trim(),'phone':phone.text.trim(),'email':email.text.trim()});
    if(!mounted)return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Company profile saved.')));
  }
  @override void dispose(){name.dispose();gstin.dispose();address.dispose();phone.dispose();email.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Company & GSTIN')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      TextField(controller:name,decoration:const InputDecoration(labelText:'Business name')),
      TextField(controller:gstin,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'GSTIN')),
      TextField(controller:address,maxLines:3,decoration:const InputDecoration(labelText:'Business address')),
      TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone')),
      TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email')),
      const SizedBox(height:24),
      FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('Save Company Profile')),
    ]));
}
