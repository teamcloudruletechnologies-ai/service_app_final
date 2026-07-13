import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});

  final BookingItem booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _apiService = ApiService();
  bool _loading = false;
  String _paymentMethod = 'card'; // card, upi, netbanking
  final _cardNumberCtrl = TextEditingController(text: '4321 8876 5432 1098');
  final _expiryCtrl = TextEditingController(text: '12/29');
  final _cvvCtrl = TextEditingController(text: '123');
  final _upiCtrl = TextEditingController(text: 'customer@okaxis');

  @override
  void initState() {
    super.initState();
    _apiService.init();
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _loading = true);
    try {
      // 1. Create order on backend
      final orderData = await _apiService.createPaymentOrder(widget.booking.id);
      final orderId = orderData['orderId'] as String;

      // Simulate payment network delay
      await Future.delayed(const Duration(seconds: 2));

      // 2. Verify payment on backend with mock values
      await _apiService.verifyPayment(
        bookingId: widget.booking.id,
        razorpayPaymentId: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        razorpaySignature: 'mock_signature',
        razorpayOrderId: orderId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Booking Confirmed.')),
        );
        // Refresh bookings list
        context.read<BookingProvider>().loadBookings();
        
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Success'),
              ],
            ),
            content: const Text('Your payment was processed successfully. The service professional has been confirmed.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (_) => false,
                  );
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Failed: $err')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Checkout')),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Processing secure payment...',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Do not close or press back', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Booking Summary Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking.serviceName ?? 'Home Service',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Booking ID', style: TextStyle(color: Colors.grey.shade600)),
                              Text('#${widget.booking.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Service Fee', style: TextStyle(color: Colors.grey.shade600)),
                              Text('₹${widget.booking.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                '₹${widget.booking.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 12),
                  // Payment options
                  _buildPaymentOptionTile(
                    id: 'card',
                    title: 'Credit / Debit Card',
                    icon: Icons.credit_card,
                  ),
                  _buildPaymentOptionTile(
                    id: 'upi',
                    title: 'UPI (GPay / PhonePe / BHIM)',
                    icon: Icons.account_balance_wallet,
                  ),
                  _buildPaymentOptionTile(
                    id: 'netbanking',
                    title: 'Net Banking',
                    icon: Icons.corporate_fare,
                  ),
                  const SizedBox(height: 24),
                  // Method details
                  if (_paymentMethod == 'card') _buildCardForm(),
                  if (_paymentMethod == 'upi') _buildUpiForm(),
                  if (_paymentMethod == 'netbanking') _buildNetbankingSelector(),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: AppTheme.primary,
                    ),
                    child: Text(
                      'Pay Securely ₹${widget.booking.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOptionTile({required String id, required String title, required IconData icon}) {
    final selected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.primary : Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.black : Colors.grey.shade800,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
            else
              Icon(Icons.radio_button_off, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _cardNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                prefixIcon: Icon(Icons.credit_card),
                hintText: '4321 8876 5432 1098',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvvCtrl,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUpiForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _upiCtrl,
          decoration: const InputDecoration(
            labelText: 'UPI ID',
            prefixIcon: Icon(Icons.flash_on),
            hintText: 'username@bank',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    );
  }

  Widget _buildNetbankingSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: 'sbi',
          decoration: const InputDecoration(labelText: 'Select Bank'),
          items: const [
            DropdownMenuItem(value: 'sbi', child: Text('State Bank of India')),
            DropdownMenuItem(value: 'hdfc', child: Text('HDFC Bank')),
            DropdownMenuItem(value: 'icici', child: Text('ICICI Bank')),
            DropdownMenuItem(value: 'axis', child: Text('Axis Bank')),
          ],
          onChanged: (val) {},
        ),
      ),
    );
  }
}
