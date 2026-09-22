import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import 'database_service.dart';

class PdfService {
  static Future<Uint8List> buildInvoicePdf(Invoice invoice) async {
    final company = await DatabaseService.instance.getCompany();
    final doc = pw.Document();
    final date = DateFormat('dd MMM yyyy').format(invoice.date.toLocal());
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      company['name']?.toString().isNotEmpty == true ? company['name'].toString() : 'InvoicePro',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    if ((company['gstin'] ?? '').toString().isNotEmpty) pw.Text('GSTIN: ${company['gstin']}'),
                    if ((company['address'] ?? '').toString().isNotEmpty) pw.Text(company['address'].toString()),
                    if ((company['phone'] ?? '').toString().isNotEmpty) pw.Text('Phone: ${company['phone']}'),
                    if ((company['email'] ?? '').toString().isNotEmpty) pw.Text('Email: ${company['email']}'),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Invoice: ${invoice.invoiceNumber}'),
                  pw.Text('Date: $date'),
                ],
              ),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Bill To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(invoice.customerName),
          if (invoice.customerAddress.isNotEmpty) pw.Text(invoice.customerAddress),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['Description', 'Qty', 'Rate', 'Amount'],
            data: invoice.items.map((i) => [
              i.description,
              i.quantity.toStringAsFixed(2),
              currency.format(i.rate),
              currency.format(i.amount),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Subtotal: ${currency.format(invoice.subtotal)}'),
                pw.Text('GST (${invoice.gstRate.toStringAsFixed(2)}%): ${currency.format(invoice.gstAmount)}'),
                pw.SizedBox(height: 4),
                pw.Text('TOTAL: ${currency.format(invoice.total)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Text('Thank you for your business.', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
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
