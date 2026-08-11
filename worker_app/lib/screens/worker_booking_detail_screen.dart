import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  Future<void> _loadBooking({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final api = context.read<ApiService>();
      final item = await api.fetchBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = item;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!isSilent && _booking == null) {
            _error = e.toString();
          }
          _loading = false;
        });
      }
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
            title: Text(
              isStart ? 'Enter Job Start OTP' : 'Enter Job Completion OTP',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15)),
                child: Text(
                  isStart ? 'Verify & Start' : 'Verify & Complete',
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
      if (otpInput == null) return; // Cancelled
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!mounted) return;
    try {
      setState(() {
        _updating = true;
      });

      final api = context.read<ApiService>();
      final updatedItem = await api.updateBookingStatus(widget.bookingId, status, otp: otpInput);

      if (!mounted) return;

      setState(() {
        _booking = updatedItem;
        _updating = false;
      });

      try {
        context.read<BookingProvider>().loadBookings();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to ${status.replaceAll('_', ' ')}'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (mounted) {
        final errorMsg = e is ApiException ? e.message : 'Error updating status: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.zomatoRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.chevron_right_rounded, color: Color(0xFF0F172A), size: 24),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_updating)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(width: 14),
                      Text(
                        'Updating Job...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _booking != null ? _buildActionButtons() : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Loading booking details...');
    if (_error != null) return ErrorView(message: _error!, onRetry: _loadBooking);
    if (_booking == null) return const Center(child: Text('Booking not found'));

    final b = _booking!;
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFmt.format(b.scheduledAt ?? b.createdAt);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // ─── 1. TOP ID & STATUS BADGE ROW ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ID. #US${b.id}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            _buildStatusBadge(b.status),
          ],
        ),

        const SizedBox(height: 24),

        // ─── 2. CUSTOMER DETAILS SECTION (Phone Call & Camera Icons REMOVED per user directive) ───
        const Text(
          'Customer Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, size: 26, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.userName ?? 'Ramesh Kumar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.userPhone != null && b.userPhone!.isNotEmpty ? b.userPhone! : '+91 98765 43210',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 18),

        // ─── 3. SERVICE SECTION ───
        const Text(
          'Service',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          b.serviceName ?? 'Plumbing Service',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          b.notes != null && b.notes!.isNotEmpty ? b.notes! : 'Bathroom Pipe Leak',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 18),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 18),

        // ─── 4. DATE & TIME SECTION ───
        const Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 18),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 18),

        // ─── 5. LOCATION SECTION ───
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  Text(
                    (b.address != null && b.address!.isNotEmpty
                            ? b.address!.replaceAll(RegExp(r'[\r\n]+'), ', ').replaceAll(RegExp(r'\s+'), ' ').trim()
                            : 'Anna Nagar, Madurai'),
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text(
                        '1.2 km away',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkerInAppNavigationScreen(
                      bookingId: b.id,
                      customerName: b.userName ?? 'Customer',
                      customerAddress: b.address ?? 'Customer Location',
                      initialLat: b.latitude,
                      initialLng: b.longitude,
                    ),
                  ),
                ).then((_) => _loadBooking());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'View on Map',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 18),

        // ─── 6. AMOUNT SECTION ───
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '₹${b.amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STATUS BADGE PILL COMPONENT ───
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'confirmed':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        label = 'Confirmed';
        break;
      case 'in_progress':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        label = 'In Progress';
        break;
      case 'pending':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFC2410C);
        label = 'Pending';
        break;
      case 'completed':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        label = 'Cancelled';
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        label = status.replaceAll('_', ' ').toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ─── BOTTOM ACTION BUTTONS (Cancel Job & Start Job) ───
  Widget? _buildActionButtons() {
    if (_booking == null) return null;
    final b = _booking!;
    final status = b.status;

    if (status == 'completed' || status == 'cancelled') return null;

    String startLabel = 'Start Job';
    if (status == 'pending') {
      startLabel = 'Accept Job';
    } else if (status == 'in_progress') {
      startLabel = 'Finish & Invoice';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Row(
          children: [
            // Left Button: Cancel Job
            if (status == 'pending' || status == 'confirmed')
              Expanded(
                child: OutlinedButton(
                  onPressed: _updating ? null : () => _confirmCancel(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Cancel Job',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

            if (status == 'pending' || status == 'confirmed') const SizedBox(width: 14),

            // Right Button: Start Job / Accept Job / Finish & Invoice
            Expanded(
              child: ElevatedButton(
                onPressed: _updating
                    ? null
                    : () {
                        if (status == 'pending') {
                          _updateStatus('confirmed');
                        } else if (status == 'confirmed') {
                          _updateStatus('in_progress');
                        } else if (status == 'in_progress') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WorkerCreateInvoiceScreen(
                                bookingId: b.id,
                                serviceName: b.serviceName ?? 'Service #${b.serviceId}',
                                customerName: b.userName ?? 'Customer',
                              ),
                            ),
                          ).then((res) {
                            if (res == true) _loadBooking();
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15), // Vibrant Yellow Accent
                  foregroundColor: const Color(0xFF0F172A),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  startLabel,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel this job?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('The customer will be notified that you cancelled this job.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Future.delayed(const Duration(milliseconds: 150));
      _updateStatus('cancelled');
    }
  }
}
