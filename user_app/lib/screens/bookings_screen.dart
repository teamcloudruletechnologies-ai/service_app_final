import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'booking_form_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isLoggedIn) {
        _load();
      }
    });
  }

  void _load() {
    context.read<BookingProvider>().loadBookings(status: _statusFilter);
  }

  Future<void> _cancelBooking(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.translate('cancel_booking_title')),
        content: Text(context.translate('cancel_booking_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.translate('no'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.translate('yes_cancel'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<BookingProvider>().cancelBooking(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? context.translate('booking_cancelled') : context.translate('failed_to_cancel'))),
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
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            context.translate('my_bookings'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A1A)),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          surfaceTintColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month_outlined, size: 64, color: AppTheme.secondary),
                ),
                const SizedBox(height: 24),
                Text(
                  context.translate('guest_mode'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  context.translate('login_prompt'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(180, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.translate('login_register'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.translate('my_bookings'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1A1A)),
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
                  label: context.translate('cat_all'),
                  selected: _statusFilter == null,
                  onSelected: () {
                    setState(() => _statusFilter = null);
                    context.read<BookingProvider>().loadBookings();
                  },
                ),
                _FilterChip(
                  label: context.translate('status_pending'),
                  selected: _statusFilter == 'pending',
                  onSelected: () {
                    setState(() => _statusFilter = 'pending');
                    context.read<BookingProvider>().loadBookings(status: 'pending');
                  },
                ),
                _FilterChip(
                  label: context.translate('status_confirmed'),
                  selected: _statusFilter == 'confirmed',
                  onSelected: () {
                    setState(() => _statusFilter = 'confirmed');
                    context.read<BookingProvider>().loadBookings(status: 'confirmed');
                  },
                ),
                _FilterChip(
                  label: context.translate('status_completed'),
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
                    ? ErrorView(message: booking.error ?? 'Unknown error', onRetry: _load)
                    : booking.bookings.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () async => _load(),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                height: MediaQuery.of(context).size.height * 0.55,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondary.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.secondary),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'No Bookings Found',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You have no active or previous service bookings under this filter.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _load,
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Refresh Bookings'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size.zero,
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _load(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: booking.bookings.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 0),
                              itemBuilder: (context, index) {
                                try {
                                  final item = booking.bookings[index];
                                  return BookingCard(
                                    booking: item,
                                    onCancel: item.canCancel ? () => _cancelBooking(item.id) : null,
                                    onRebook: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BookingFormScreen(
                                            service: ServiceItem(
                                              id: item.serviceId ?? 0,
                                              name: item.serviceName ?? context.translate('service'),
                                              price: item.amount,
                                              status: 'active',
                                            ),
                                            initialAddress: item.address,
                                            initialNotes: item.notes,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } catch (e, stack) {
                                  debugPrint("--------------------------------------------------");
                                  debugPrint("ERROR RENDERING BOOKING ITEM AT INDEX $index: $e\n$stack");
                                  debugPrint("--------------------------------------------------");
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text("Error rendering booking #${booking.bookings[index].id}: $e"),
                                  );
                                }
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
