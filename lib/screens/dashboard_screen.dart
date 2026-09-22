import 'package:flutter/material.dart';
import 'create_invoice_screen.dart';
import 'history_screen.dart';
import 'company_profile_screen.dart';
import 'customer_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('InvoicePro')),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Invoice management made simple', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        FilledButton.icon(icon: const Icon(Icons.receipt_long), label: const Text('New Invoice'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()))),
        const SizedBox(height: 12),
        OutlinedButton.icon(icon: const Icon(Icons.history), label: const Text('Invoice History'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
        const SizedBox(height: 12),
        OutlinedButton.icon(icon: const Icon(Icons.people), label: const Text('Customers'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerScreen()))),
        const SizedBox(height: 12),
        OutlinedButton.icon(icon: const Icon(Icons.business), label: const Text('Company & GSTIN'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyProfileScreen()))),
      ],
    )),
  );
}
