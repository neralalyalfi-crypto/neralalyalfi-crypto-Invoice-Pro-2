import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class HistoryScreen extends StatefulWidget{
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState()=>_HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen>{
  late Future<dynamic> invoices;
  @override void initState(){super.initState();invoices=DatabaseService.instance.getInvoices();}
  Future<void> _refresh() async=>setState(()=>invoices=DatabaseService.instance.getInvoices());
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Invoice History')),
    body:FutureBuilder(
      future:invoices,
      builder:(context,snapshot){
        if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
        if(snapshot.hasError)return Center(child:Text('Error: ${snapshot.error}'));
        final list=snapshot.data??[];
        if(list.isEmpty)return const Center(child:Text('No invoices yet.'));
        return RefreshIndicator(onRefresh:_refresh,child:ListView.builder(
          itemCount:list.length,
          itemBuilder:(_,index){
            final invoice=list[index];
            return ListTile(
              leading:const Icon(Icons.receipt_long),
              title:Text(invoice.invoiceNumber),
              subtitle:Text('${invoice.customerName} • ₹${invoice.total.toStringAsFixed(2)}'),
              trailing:IconButton(icon:const Icon(Icons.picture_as_pdf),onPressed:()=>PdfService.shareInvoice(invoice)),
            );
          },
        ));
      },
    ),
  );
}
