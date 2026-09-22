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
  final customerController = TextEditingController();
  final addressController = TextEditingController();
  final gstController = TextEditingController(text: '18');
  final invoiceNumberController = TextEditingController();
  final List<InvoiceItem> items = [];
  final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    invoiceNumberController.text = 'INV-' + DateTime.now().millisecondsSinceEpoch.toString();
    _addItem();
    _loadCatalog();
  }

  @override
  void dispose() {
    customerController.dispose();
    addressController.dispose();
    gstController.dispose();
    invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final c = await DatabaseService.instance.getCustomers();
    final p = await DatabaseService.instance.getProducts();
    if (mounted) setState(() { customers = c; products = p; });
  }

  void _addItem([Map<String, dynamic>? product]) {
    setState(() {
      items.add(InvoiceItem(
        description: product?['name']?.toString() ?? '',
        quantity: 1,
        rate: product == null ? 0 : (product['price'] as num).toDouble(),
      ));
    });
  }

  void _selectCustomer() {
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No saved customers yet.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: customers.map((c) => ListTile(
            leading: const Icon(Icons.person),
            title: Text(c['name'].toString()),
            subtitle: Text(c['phone']?.toString() ?? ''),
            onTap: () {
              customerController.text = c['name'].toString();
              addressController.text = c['address']?.toString() ?? '';
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _selectProduct(int index) {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No saved products or services yet.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: products.map((p) => ListTile(
            leading: const Icon(Icons.inventory_2),
            title: Text(p['name'].toString()),
            subtitle: Text('₹' + (p['price'] as num).toStringAsFixed(2) + ' • GST ' + p['gst_rate'].toString() + '%'),
            onTap: () {
              setState(() {
                final old = items[index];
                items[index] = InvoiceItem(
                  description: p['name'].toString(),
                  quantity: old.quantity,
                  rate: (p['price'] as num).toDouble(),
                );
                gstController.text = p['gst_rate'].toString();
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = customerController.text.trim();
    final gstRate = double.tryParse(gstController.text.trim()) ?? 0;
    if (name.isEmpty || gstRate < 0 || gstRate > 100 ||
        items.isEmpty || items.any((i) => i.description.trim().isEmpty || i.quantity <= 0 || i.rate < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a customer and valid item details.')));
      return;
    }
    final invoice = Invoice(
      invoiceNumber: invoiceNumberController.text.trim(),
      customerName: name,
      customerAddress: addressController.text.trim(),
      date: DateTime.now(),
      gstRate: gstRate,
      items: items,
    );
    final id = await DatabaseService.instance.insertInvoice(invoice);
    final saved = Invoice(
      id: id,
      invoiceNumber: invoice.invoiceNumber,
      customerName: invoice.customerName,
      customerAddress: invoice.customerAddress,
      date: invoice.date,
      gstRate: invoice.gstRate,
      items: invoice.items,
    );
    if (!mounted) return;
    await PdfService.printInvoice(saved);
    if (!mounted) return;
    Navigator.pop(context);
  }

  double get subtotal => items.fold(0, (s, i) => s + i.amount);
  double get gst => subtotal * (double.tryParse(gstController.text) ?? 0) / 100;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Invoice')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: invoiceNumberController, decoration: const InputDecoration(labelText: 'Invoice number')),
      Row(children: [
        Expanded(child: TextField(controller: customerController, decoration: const InputDecoration(labelText: 'Customer name'))),
        IconButton(onPressed: _selectCustomer, icon: const Icon(Icons.people), tooltip: 'Choose saved customer'),
      ]),
      TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Customer address')),
      TextField(
        controller: gstController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'GST %'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      ...List.generate(items.length, (index) {
        final item = items[index];
        return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Row(children: [
            Expanded(child: Text('Item ' + (index + 1).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
            TextButton.icon(onPressed: () => _selectProduct(index), icon: const Icon(Icons.inventory_2), label: const Text('Choose product')),
          ]),
          TextFormField(
            initialValue: item.description,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => items[index] = InvoiceItem(description: v, quantity: items[index].quantity, rate: items[index].rate),
          ),
          Row(children: [
            Expanded(child: TextFormField(
              initialValue: item.quantity.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Qty'),
              onChanged: (v) => setState(() => items[index] = InvoiceItem(description: items[index].description, quantity: double.tryParse(v) ?? 0, rate: items[index].rate)),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              initialValue: item.rate.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Rate'),
              onChanged: (v) => setState(() => items[index] = InvoiceItem(description: items[index].description, quantity: items[index].quantity, rate: double.tryParse(v) ?? 0)),
            )),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => items.removeAt(index))),
          ]),
        ])));
      }),
      TextButton.icon(onPressed: () => _addItem(), icon: const Icon(Icons.add), label: const Text('Add item')),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('Subtotal: ' + currency.format(subtotal)),
        Text('GST: ' + currency.format(gst)),
        Text('Total: ' + currency.format(subtotal + gst), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ]))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save & Print PDF')),
    ]),
  );
}
