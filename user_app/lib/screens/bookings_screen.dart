import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'profile_screen.dart';

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

  Widget _buildProfileButton(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final initial = (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      child: Hero(
        tag: 'profile_avatar_hero_bookings',
        child: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE3D0BA),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A1A1A),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildProfileButton(context),
          ),
        ],
      ),
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
          const Divider(height: 1),
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
                              separatorBuilder: (_, __) => const SizedBox(height: 0),
                              itemBuilder: (context, index) {
                                final item = booking.bookings[index];
                                return BookingCard(
                                  booking: item,
                                  onCancel: item.canCancel ? () => _cancelBooking(item.id) : null,
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
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.secondary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.secondary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
