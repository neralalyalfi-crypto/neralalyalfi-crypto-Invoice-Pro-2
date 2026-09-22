import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';

class PdfService {
  static Future<Uint8List> buildInvoicePdf(Invoice invoice) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (_) => [
      pw.Text('InvoicePro', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.Text('Invoice: ${invoice.invoiceNumber}'),
      pw.Text('Date: ${invoice.date.toLocal().toString().split(' ').first}'),
      pw.Text('Customer: ${invoice.customerName}'),
      if (invoice.customerAddress.isNotEmpty) pw.Text(invoice.customerAddress),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(
        headers: ['Description','Qty','Rate','Amount'],
        data: invoice.items.map((i) => [i.description,i.quantity.toStringAsFixed(2),i.rate.toStringAsFixed(2),i.amount.toStringAsFixed(2)]).toList(),
      ),
      pw.SizedBox(height: 16),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Subtotal: ${invoice.subtotal.toStringAsFixed(2)}')),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('GST (${invoice.gstRate.toStringAsFixed(2)}%): ${invoice.gstAmount.toStringAsFixed(2)}')),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('TOTAL: ${invoice.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
    ]));
    return doc.save();
  }
  static Future<void> printInvoice(Invoice invoice) async {
    final bytes = await buildInvoicePdf(invoice);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
  static Future<void> shareInvoice(Invoice invoice) async {
    final bytes = await buildInvoicePdf(invoice);
    await Printing.sharePdf(bytes: bytes, filename: '${invoice.invoiceNumber}.pdf');
  }
}
