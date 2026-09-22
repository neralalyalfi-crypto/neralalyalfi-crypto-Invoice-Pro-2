import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});
  @override State<ProductScreen> createState()=>_ProductScreenState();
}
class _ProductScreenState extends State<ProductScreen>{
  String search='';
  Future<void> _edit([Map<String,dynamic>? product]) async {
    final name=TextEditingController(text:product?['name']??'');
    final description=TextEditingController(text:product?['description']??'');
    final code=TextEditingController(text:product?['code']??'');
    final unit=TextEditingController(text:product?['unit']??'pcs');
    final price=TextEditingController(text:product?['price']?.toString()??'');
    final gst=TextEditingController(text:product?['gst_rate']?.toString()??'18');
    await showDialog(context:context,builder:(_)=>AlertDialog(
      title:Text(product==null?'Add Product / Service':'Edit Product / Service'),
      content:SingleChildScrollView(child:Column(children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Name *')),
        TextField(controller:description,decoration:const InputDecoration(labelText:'Description')),
        TextField(controller:code,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Code / SKU')),
        TextField(controller:unit,decoration:const InputDecoration(labelText:'Unit')),
        TextField(controller:price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Price / Rate *')),
        TextField(controller:gst,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'GST %')),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
        FilledButton(onPressed:()async{
          final parsedPrice=double.tryParse(price.text.trim());
          final parsedGst=double.tryParse(gst.text.trim())??0;
          if(name.text.trim().isEmpty||parsedPrice==null)return;
          final data={'name':name.text.trim(),'description':description.text.trim(),'code':code.text.trim(),'unit':unit.text.trim().isEmpty?'pcs':unit.text.trim(),'price':parsedPrice,'gst_rate':parsedGst};
          if(product==null) await DatabaseService.instance.addProduct(data);
          else await DatabaseService.instance.updateProduct(product['id'] as int,data);
          if(context.mounted)Navigator.pop(context);
          setState((){});
        },child:const Text('Save'))
      ]
    ));
    name.dispose();description.dispose();code.dispose();unit.dispose();price.dispose();gst.dispose();
  }
  Future<void> _delete(int id) async { await DatabaseService.instance.deleteProduct(id); setState((){}); }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Products & Services'),actions:[IconButton(onPressed:()=>_edit(),icon:const Icon(Icons.add_box))]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:TextField(
        onChanged:(v)=>setState(()=>search=v),
        decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'Search products and services',border:OutlineInputBorder())
      )),
      Expanded(child:FutureBuilder(
        future:DatabaseService.instance.getProducts(query:search),
        builder:(context,s){
          if(!s.hasData)return const Center(child:CircularProgressIndicator());
          final list=s.data!;
          if(list.isEmpty)return const Center(child:Text('No products or services yet.'));
          return ListView.builder(itemCount:list.length,itemBuilder:(_,i){
            final p=list[i];
            return ListTile(
              leading:const CircleAvatar(child:Icon(Icons.inventory_2)),
              title:Text(p['name']),
              subtitle:Text('${p['code'] ?? ''}${p['code'].toString().isNotEmpty ? ' • ' : ''}${p['unit']} • GST ${p['gst_rate']}%'),
              trailing:Text('₹${(p['price'] as num).toStringAsFixed(2)}'),
              onTap:()=>_edit(p),
              onLongPress:()=>_delete(p['id'] as int),
            );
          });
        }
      ))
    ]),
  );
}