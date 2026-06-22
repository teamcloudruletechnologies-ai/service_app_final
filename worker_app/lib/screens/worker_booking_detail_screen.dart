import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
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
      _loadBooking(); // Reload details
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bookingProv.error ?? 'Failed to update status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Job Details')),
      body: _buildBody(),
      bottomNavigationBar: _booking != null ? _buildActionButtons() : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Loading job details...');
    if (_error != null) return ErrorView(message: _error!, onRetry: _loadBooking);
    if (_booking == null) return const Center(child: Text('Job not found'));

    final b = _booking!;
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header Card (Service + Price + Status)
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.serviceName ?? 'Service #${b.serviceId}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '₹${b.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        b.status.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Customer Details
        const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Client Name',
                  value: b.userName ?? 'Guest Customer',
                ),
                const Divider(height: 16),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Client Phone',
                  value: b.userPhone ?? 'No contact info',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Service Details
        const Text('Schedule & Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Scheduled At',
                  value: dateFmt.format(b.scheduledAt ?? b.createdAt),
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: b.address ?? 'No address provided',
                ),
                if (b.notes != null && b.notes!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.note_alt_outlined,
                    label: 'Notes',
                    value: b.notes!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildActionButtons() {
    if (_booking == null || _updating) return null;
    final status = _booking!.status;

    Widget btn;
    if (status == 'pending') {
      btn = ElevatedButton(
        onPressed: () => _updateStatus('confirmed'),
        child: const Text('Accept Job Request'),
      );
    } else if (status == 'confirmed') {
      btn = ElevatedButton(
        onPressed: () => _updateStatus('in_progress'),
        child: const Text('Start Job Service'),
      );
    } else if (status == 'in_progress') {
      btn = ElevatedButton(
        onPressed: () => _updateStatus('completed'),
        child: const Text('Complete Job Service'),
      );
    } else {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: btn,
      ),
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
        Icon(icon, size: 20, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
