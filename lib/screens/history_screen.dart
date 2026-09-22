import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Invoice>> invoices;

  @override
  void initState() {
    super.initState();
    _refreshFuture();
  }

  void _refreshFuture() {
    invoices = DatabaseService.instance.getInvoices();
  }

  Future<void> _refresh() async {
    setState(_refreshFuture);
    await invoices;
  }

  Future<void> _delete(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text('Delete ${invoice.invoiceNumber}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || invoice.id == null) return;
    await DatabaseService.instance.deleteInvoice(invoice.id!);
    if (mounted) setState(_refreshFuture);
  }

  Future<void> _actions(Invoice invoice) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print invoice'),
              onTap: () async { Navigator.pop(context); await PdfService.printInvoice(invoice); },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share PDF'),
              onTap: () async { Navigator.pop(context); await PdfService.shareInvoice(invoice); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete invoice'),
              onTap: () async { Navigator.pop(context); await _delete(invoice); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Invoice History')),
    body: FutureBuilder<List<Invoice>>(
      future: invoices,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        final list = snapshot.data ?? <Invoice>[];
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(children: const [SizedBox(height: 220), Center(child: Text('No invoices yet.'))]),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, index) {
              final invoice = list[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                title: Text(invoice.invoiceNumber),
                subtitle: Text('${invoice.customerName} • ₹${invoice.total.toStringAsFixed(2)}'),
                trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _actions(invoice)),
                onTap: () => _actions(invoice),
              );
            },
          ),
        );
      },
    ),
  );
}
