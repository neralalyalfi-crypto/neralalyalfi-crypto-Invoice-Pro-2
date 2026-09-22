import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});
  @override State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}
class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final customerController=TextEditingController();
  final addressController=TextEditingController();
  final gstController=TextEditingController(text:'18');
  final invoiceNumberController=TextEditingController();
  final List<InvoiceItem> items=[];
  final currency=NumberFormat.currency(locale:'en_IN',symbol:'₹');

  @override void initState(){super.initState();invoiceNumberController.text='INV-${DateTime.now().millisecondsSinceEpoch}';_addItem();}
  @override void dispose(){customerController.dispose();addressController.dispose();gstController.dispose();invoiceNumberController.dispose();super.dispose();}
  void _addItem()=>setState(()=>items.add(const InvoiceItem(description:'',quantity:1,rate:0)));

  Future<void> _save() async {
    final name=customerController.text.trim();
    if(name.isEmpty||items.any((i)=>i.description.trim().isEmpty||i.quantity<=0)){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter customer name and valid item details.'))); return;
    }
    final invoice=Invoice(invoiceNumber:invoiceNumberController.text.trim(),customerName:name,customerAddress:addressController.text.trim(),date:DateTime.now(),gstRate:double.tryParse(gstController.text)??0,items:items);
    final id=await DatabaseService.instance.insertInvoice(invoice);
    final saved=Invoice(id:id,invoiceNumber:invoice.invoiceNumber,customerName:invoice.customerName,customerAddress:invoice.customerAddress,date:invoice.date,gstRate:invoice.gstRate,items:invoice.items);
    if(!mounted)return;
    await PdfService.printInvoice(saved);
    if(!mounted)return;
    Navigator.pop(context);
  }
  double get subtotal=>items.fold(0,(s,i)=>s+i.amount);
  double get gst=>subtotal*(double.tryParse(gstController.text)??0)/100;

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Create Invoice')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      TextField(controller:invoiceNumberController,decoration:const InputDecoration(labelText:'Invoice number')),
      TextField(controller:customerController,decoration:const InputDecoration(labelText:'Customer name')),
      TextField(controller:addressController,decoration:const InputDecoration(labelText:'Customer address')),
      TextField(controller:gstController,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'GST %')),
      const SizedBox(height:20),
      ...List.generate(items.length,(index){
        final item=items[index];
        return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
          TextField(initialValue:item.description,decoration:const InputDecoration(labelText:'Description'),onChanged:(v)=>items[index]=InvoiceItem(description:v,quantity:item.quantity,rate:item.rate)),
          Row(children:[
            Expanded(child:TextField(initialValue:item.quantity.toString(),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Qty'),onChanged:(v)=>setState(()=>items[index]=InvoiceItem(description:items[index].description,quantity:double.tryParse(v)??0,rate:items[index].rate)))),
            const SizedBox(width:12),
            Expanded(child:TextField(initialValue:item.rate.toString(),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Rate'),onChanged:(v)=>setState(()=>items[index]=InvoiceItem(description:items[index].description,quantity:items[index].quantity,rate:double.tryParse(v)??0)))),
            IconButton(icon:const Icon(Icons.delete),onPressed:()=>setState(()=>items.removeAt(index))),
          ]),
        ])));
      }),
      TextButton.icon(onPressed:_addItem,icon:const Icon(Icons.add),label:const Text('Add item')),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
        Text('Subtotal: ${currency.format(subtotal)}'),
        Text('GST: ${currency.format(gst)}'),
        Text('Total: ${currency.format(subtotal+gst)}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
      ]))),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('Save & Print PDF')),
    ]),
  );
}
