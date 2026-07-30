import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'worker_create_invoice_screen.dart';
import 'worker_in_app_navigation_screen.dart';

class WorkerBookingDetailScreen extends StatefulWidget {
  const WorkerBookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<WorkerBookingDetailScreen> createState() => _WorkerBookingDetailScreenState();
}

class _WorkerBookingDetailScreenState extends State<WorkerBookingDetailScreen> {
  BookingItem? _booking;
  bool _loading = true;
  String? _error;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final item = await api.fetchBooking(widget.bookingId);
      setState(() {
        _booking = item;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String status, {String? otp}) async {
    String? otpInput = otp;
    if (otpInput == null && (status == 'in_progress' || status == 'completed')) {
      final isStart = status == 'in_progress';
      otpInput = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final ctrl = TextEditingController();
          final formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(isStart ? 'Enter Job Start OTP' : 'Enter Job Completion OTP', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isStart
                        ? 'Please ask the customer for the 4-digit code shown on their booking card to verify your arrival.'
                        : 'Please ask the customer for the 4-digit code shown on their booking card to verify completion.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ctrl,
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
                    validator: (v) {
                      if (v == null || v.trim().length != 4) {
                        return 'Enter 4-digit code';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, ctrl.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: Text(isStart ? 'Verify & Start' : 'Verify & Complete', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      if (otpInput == null) return; // Cancelled
    }

    setState(() {
      _updating = true;
    });

    final bookingProv = context.read<BookingProvider>();
    final ok = await bookingProv.updateBookingStatus(widget.bookingId, status, otp: otpInput);

    if (!mounted) return;
    setState(() {
      _updating = false;
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking status updated to $status')),
      );
      _loadBooking();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bookingProv.error ?? 'Failed to update status')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.zomatoRed;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return AppTheme.olive;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: _booking != null && !_updating
          ? _buildActionButton()
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Loading order details...');
    if (_error != null) return ErrorView(message: _error!, onRetry: _loadBooking);
    if (_booking == null) return const Center(child: Text('Order not found'));

    final b = _booking!;
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Order #ID and Status Badge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${b.id}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFmt.format(b.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(b.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  b.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(b.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Service Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      b.serviceName ?? 'Service #${b.serviceId}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  Text(
                    '₹${b.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Customer Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 12),
              _CustomerRow(
                icon: Icons.person_outline,
                label: b.userName ?? 'Guest Customer',
                trailing: null,
              ),
              const SizedBox(height: 14),
              _CustomerRow(
                icon: Icons.location_on_outlined,
                label: b.address ?? 'No address provided',
                trailing: null,
              ),
              if (b.address != null && b.address!.isNotEmpty && (b.status == 'confirmed' || b.status == 'in_progress')) ...[
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkerInAppNavigationScreen(
                          bookingId: b.id,
                          customerName: b.userName ?? 'Customer',
                          customerAddress: b.address!,
                          initialLat: b.latitude,
                          initialLng: b.longitude,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                  label: const Text('Start In-App Map Navigation 📍', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Schedule & Notes
        if (b.scheduledAt != null || (b.notes != null && b.notes!.isNotEmpty))
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 12),
                if (b.scheduledAt != null) ...[
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Scheduled At',
                    value: dateFmt.format(b.scheduledAt!),
                  ),
                  if (b.notes != null && b.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                  ],
                ],
                if (b.notes != null && b.notes!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.note_alt_outlined,
                    label: 'Notes',
                    value: b.notes!,
                  ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Status Timeline
        _buildTimeline(b),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTimeline(BookingItem b) {
    final statuses = [
      {'label': 'Booked', 'status': 'pending', 'icon': Icons.receipt_long_outlined},
      {'label': 'Confirmed', 'status': 'confirmed', 'icon': Icons.check_circle_outline},
      {'label': 'In Progress', 'status': 'in_progress', 'icon': Icons.play_circle_outline},
      {'label': 'Completed', 'status': 'completed', 'icon': Icons.done_all_outlined},
    ];

    final statusOrder = ['pending', 'confirmed', 'in_progress', 'completed'];
    final currentIdx = statusOrder.indexOf(b.status);
    final isCancelled = b.status == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Timeline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 16),
          ...statuses.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final isCompleted = !isCancelled && idx <= currentIdx;
            final isCurrent = !isCancelled && idx == currentIdx;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? AppTheme.olive : Colors.grey.shade200,
                      ),
                      child: Icon(
                        s['icon'] as IconData,
                        size: 14,
                        color: isCompleted ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                    if (idx < statuses.length - 1)
                      Container(
                        width: 2,
                        height: 32,
                        color: isCompleted ? AppTheme.olive.withValues(alpha: 0.3) : Colors.grey.shade200,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${s['label']}${isCurrent ? ' (Current)' : ''}',
                      style: TextStyle(
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                        color: isCompleted ? AppTheme.primary : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          if (isCancelled)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CANCELLED',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildActionButton() {
    if (_booking == null) return null;
    final b = _booking!;
    final status = b.status;

    String label;
    Color color;
    VoidCallback? onPressed;

    if (status == 'pending') {
      label = 'Accept Job';
      color = AppTheme.olive;
      onPressed = () => _updateStatus('confirmed');
    } else if (status == 'confirmed') {
      label = 'Enter Customer OTP to Start';
      color = Colors.blue;
      onPressed = () => _promptOtpAndStart();
    } else if (status == 'in_progress') {
      label = 'Generate Custom Invoice & Finish';
      color = AppTheme.primary;
      onPressed = () async {
        final res = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkerCreateInvoiceScreen(
              bookingId: b.id,
              serviceName: b.serviceName ?? 'Service #${b.serviceId}',
              customerName: b.userName ?? 'Customer',
            ),
          ),
        );
        if (res == true) {
          _loadBooking();
        }
      };
    } else {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _promptOtpAndStart() async {
    final ctrl = TextEditingController();
    final otp = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Customer Start OTP', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ask the customer for the 4-digit OTP shown on their app to verify arrival.'),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. 4829',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Verify & Start'),
          ),
        ],
      ),
    );

    if (otp != null && otp.isNotEmpty) {
      _updateStatus('in_progress', otp: otp);
    }
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
