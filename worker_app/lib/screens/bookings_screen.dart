import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/booking_provider.dart';
import '../widgets/common_widgets.dart';
import 'worker_booking_detail_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<BookingProvider>().loadBookings(status: _statusFilter);
  }

  Future<void> _cancelBooking(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<BookingProvider>().cancelBooking(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Booking cancelled' : 'Failed to cancel booking')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('My Bookings')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _statusFilter == null,
                  onSelected: () {
                    setState(() => _statusFilter = null);
                    context.read<BookingProvider>().loadBookings();
                  },
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: _statusFilter == 'pending',
                  onSelected: () {
                    setState(() => _statusFilter = 'pending');
                    context.read<BookingProvider>().loadBookings(status: 'pending');
                  },
                ),
                _FilterChip(
                  label: 'Confirmed',
                  selected: _statusFilter == 'confirmed',
                  onSelected: () {
                    setState(() => _statusFilter = 'confirmed');
                    context.read<BookingProvider>().loadBookings(status: 'confirmed');
                  },
                ),
                _FilterChip(
                  label: 'Completed',
                  selected: _statusFilter == 'completed',
                  onSelected: () {
                    setState(() => _statusFilter = 'completed');
                    context.read<BookingProvider>().loadBookings(status: 'completed');
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: booking.loading
                ? const LoadingView(message: 'Loading bookings...')
                : booking.error != null
                    ? ErrorView(message: booking.error!, onRetry: _load)
                    : booking.bookings.isEmpty
                        ? const Center(child: Text('No bookings yet'))
                        : RefreshIndicator(
                            onRefresh: () async => _load(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: booking.bookings.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = booking.bookings[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => WorkerBookingDetailScreen(bookingId: item.id),
                                      ),
                                    ).then((_) => _load());
                                  },
                                  child: BookingCard(
                                    booking: item,
                                    onCancel: item.canCancel ? () => _cancelBooking(item.id) : null,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onSelected()),
    );
  }
}
