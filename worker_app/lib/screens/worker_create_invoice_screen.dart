import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class InvoiceItemRow {
  TextEditingController descriptionCtrl;
  TextEditingController amountCtrl;

  InvoiceItemRow({String desc = '', String amt = ''})
      : descriptionCtrl = TextEditingController(text: desc),
        amountCtrl = TextEditingController(text: amt);
}

class WorkerCreateInvoiceScreen extends StatefulWidget {
  const WorkerCreateInvoiceScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
    required this.customerName,
  });

  final int bookingId;
  final String serviceName;
  final String customerName;

  @override
  State<WorkerCreateInvoiceScreen> createState() => _WorkerCreateInvoiceScreenState();
}

class _WorkerCreateInvoiceScreenState extends State<WorkerCreateInvoiceScreen> {
  final List<InvoiceItemRow> _rows = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Default 1 row
    _rows.add(InvoiceItemRow(desc: widget.serviceName, amt: '500'));
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.descriptionCtrl.dispose();
      row.amountCtrl.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(InvoiceItemRow());
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final row = _rows.removeAt(index);
      row.descriptionCtrl.dispose();
      row.amountCtrl.dispose();
    });
  }

  double get _totalAmount {
    double sum = 0;
    for (final row in _rows) {
      final val = double.tryParse(row.amountCtrl.text.trim()) ?? 0;
      sum += val;
    }
    return sum;
  }

  Future<void> _submitInvoice() async {
    final items = <Map<String, dynamic>>[];
    for (final row in _rows) {
      final desc = row.descriptionCtrl.text.trim();
      final amt = double.tryParse(row.amountCtrl.text.trim()) ?? 0;
      if (desc.isNotEmpty && amt > 0) {
        items.add({'description': desc, 'amount': amt});
      }
    }

    if (items.isEmpty || _totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one valid work item and amount')),
      );
      return;
    }

    final otpCtrl = TextEditingController();
    final otpInput = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Customer Finish OTP', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please ask the customer for the 4-digit Finish OTP code shown on their booking card to verify job completion.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '0000',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (otpCtrl.text.trim().length == 4) {
                Navigator.pop(ctx, otpCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Verify & Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (otpInput == null || otpInput.length != 4) return;

    setState(() => _submitting = true);

    try {
      final api = context.read<ApiService>();
      await api.postRaw('/app/bookings/${widget.bookingId}/submit-invoice', {
        'items': items,
        'totalAmount': _totalAmount,
        'otp': otpInput,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice of ₹${_totalAmount.toStringAsFixed(2)} submitted to Customer & Admin!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit invoice: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.milkWhite,
      appBar: AppBar(
        title: const Text('Generate Custom Invoice'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.matteBlack,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Customer & Booking Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking #${widget.bookingId} • ${widget.serviceName}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${widget.customerName}',
                          style: const TextStyle(color: AppTheme.sandal, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Work Items & Spare Charges',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.matteBlack),
                      ),
                      TextButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 20),
                        label: const Text('Add Line', style: TextStyle(color: AppTheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Item Rows List
                  ..._rows.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: row.descriptionCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Work Item (e.g. Filter Service)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row.amountCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                prefixText: '₹ ',
                                hintText: 'Amount',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          if (_rows.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeRow(idx),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Total Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.sandal),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable Amount',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '₹${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit Invoice (₹${_totalAmount.toStringAsFixed(2)}) & Finish',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
