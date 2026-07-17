import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

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

  Future<void> _updateStatus(String status) async {
    setState(() {
      _updating = true;
    });

    final bookingProv = context.read<BookingProvider>();
    final ok = await bookingProv.updateBookingStatus(widget.bookingId, status);

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
              const SizedBox(height: 12),
              _CustomerRow(
                icon: Icons.phone_outlined,
                label: b.userPhone ?? 'No contact info',
                trailing: b.userPhone != null
                    ? GestureDetector(
                        onTap: () => launchUrl(Uri.parse('tel:${b.userPhone}')),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.olive.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.call, color: AppTheme.olive, size: 18),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              _CustomerRow(
                icon: Icons.location_on_outlined,
                label: b.address ?? 'No address provided',
                trailing: b.address != null
                    ? GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(b.address!)}')),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.olive.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.navigation_outlined, color: AppTheme.olive, size: 18),
                        ),
                      )
                    : null,
              ),
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
    final status = _booking!.status;

    String label;
    Color color;
    VoidCallback? onPressed;

    if (status == 'pending') {
      label = 'Accept Job';
      color = AppTheme.olive;
      onPressed = () => _updateStatus('confirmed');
    } else if (status == 'confirmed') {
      label = 'Start Service';
      color = Colors.blue;
      onPressed = () => _updateStatus('in_progress');
    } else if (status == 'in_progress') {
      label = 'Mark Complete';
      color = AppTheme.olive;
      onPressed = () => _updateStatus('completed');
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
