import 'package:flutter_test/flutter_test.dart';
import 'package:invoicepro/models/invoice.dart';

void main() {
  test('invoice calculates subtotal, GST and total', () {
    const invoice = Invoice(
      invoiceNumber: 'INV-1',
      customerName: 'Test Customer',
      customerAddress: '',
      date: DateTime(2026, 1, 1),
      gstRate: 18,
      items: [
        InvoiceItem(description: 'Item A', quantity: 2, rate: 100),
        InvoiceItem(description: 'Item B', quantity: 1, rate: 50),
      ],
    );

    expect(invoice.subtotal, 250);
    expect(invoice.gstAmount, 45);
    expect(invoice.total, 295);
  });
}
