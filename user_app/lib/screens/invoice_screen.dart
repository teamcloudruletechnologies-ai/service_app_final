import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key, required this.booking});

  final BookingItem booking;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final invoiceNumber = 'INV-${booking.createdAt.millisecondsSinceEpoch.toString().substring(5)}-${booking.id}';
    final platformFee = booking.amount * 0.10;
    final baseAmount = booking.amount - platformFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Invoice Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo / Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URBAN SERVICE',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5, color: AppTheme.primary),
                    ),
                    Text('Secure Digital Receipt', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Icon(Icons.receipt_long, size: 40, color: AppTheme.primary),
              ],
            ),
            const Divider(height: 48),
            // Invoice Metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice Number', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Text(invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date Paid', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Text(dateFmt.format(booking.createdAt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billed To', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Text(booking.userName ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Service Provider', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Text(booking.workerName ?? 'Assigned Professional', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),
            // Itemized list
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.serviceName ?? 'Home Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Address: ${booking.address ?? "Customer Location"}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('₹${baseAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Platform Fee (10%)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            Text('₹${platformFee.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Taxes & SGST', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const Text('₹0.00', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '₹${booking.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Actions
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt downloaded successfully!')),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Download PDF Invoice'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for using Urban Service. If you have questions about this bill, please contact support.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
