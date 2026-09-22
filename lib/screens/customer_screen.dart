import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});
  @override State<CustomerScreen> createState()=>_CustomerScreenState();
}
class _CustomerScreenState extends State<CustomerScreen>{
  String search='';
  Future<void> _edit([Map<String,dynamic>? customer]) async {
    final name=TextEditingController(text:customer?['name']??''),address=TextEditingController(text:customer?['address']??''),phone=TextEditingController(text:customer?['phone']??''),email=TextEditingController(text:customer?['email']??''),gstin=TextEditingController(text:customer?['gstin']??'');
    await showDialog(context:context,builder:(_)=>AlertDialog(title:Text(customer==null?'Add Customer':'Edit Customer'),content:SingleChildScrollView(child:Column(children:[
      TextField(controller:name,decoration:const InputDecoration(labelText:'Customer name')),
      TextField(controller:address,decoration:const InputDecoration(labelText:'Address')),
      TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone')),
      TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email')),
      TextField(controller:gstin,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'GSTIN')),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()async{
      if(name.text.trim().isEmpty)return;
      final data={'name':name.text.trim(),'address':address.text.trim(),'phone':phone.text.trim(),'email':email.text.trim(),'gstin':gstin.text.trim()};
      if(customer==null) await DatabaseService.instance.addCustomer(data); else await DatabaseService.instance.updateCustomer(customer['id'] as int,data);
      if(context.mounted)Navigator.pop(context); setState((){});
    },child:const Text('Save'))]));
    name.dispose();address.dispose();phone.dispose();email.dispose();gstin.dispose();
  }
  Future<void> _delete(int id) async { await DatabaseService.instance.deleteCustomer(id); setState((){}); }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Customers'),actions:[IconButton(onPressed:()=>_edit(),icon:const Icon(Icons.person_add))]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'Search customers',border:OutlineInputBorder()))),
      Expanded(child:FutureBuilder(future:DatabaseService.instance.getCustomers(query:search),builder:(context,s){
        if(!s.hasData)return const Center(child:CircularProgressIndicator());
        final list=s.data!;
        if(list.isEmpty)return const Center(child:Text('No customers yet.'));
        return ListView.builder(itemCount:list.length,itemBuilder:(_,i){final c=list[i];return ListTile(
          leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(c['name']),subtitle:Text([c['phone'],c['gstin']].where((x)=>x!=null&&x.toString().isNotEmpty).join(' • ')),
          onTap:()=>_edit(c),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>_delete(c['id'] as int)));
        });
      }))
    ]),
  );
}
