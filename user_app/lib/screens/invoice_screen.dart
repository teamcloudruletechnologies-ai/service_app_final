import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
            // Actions
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _generateAndDownloadPdf(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to generate PDF: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Download / Print PDF Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

  Future<void> _generateAndDownloadPdf(BuildContext context) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final invoiceNumber = 'INV-${booking.createdAt.millisecondsSinceEpoch.toString().substring(5)}-${booking.id}';
    final platformFee = booking.amount * 0.10;
    final baseAmount = booking.amount - platformFee;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('URBAN SERVICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Official Service Receipt & Tax Invoice', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Text('PAID', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                  ],
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Invoice #: $invoiceNumber'),
                    pw.Text('Date: ${dateFmt.format(booking.createdAt)}'),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Customer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(booking.userName ?? 'Customer'),
                        pw.Text(booking.address ?? ''),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Provider:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(booking.workerName ?? 'Partner Professional'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(booking.serviceName ?? 'Service Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('₹${baseAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Platform Fee (10%)'),
                          pw.Text('₹${platformFee.toStringAsFixed(2)}'),
                        ],
                      ),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.Text('₹${booking.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.green800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${booking.id}.pdf',
    );
  }
}
