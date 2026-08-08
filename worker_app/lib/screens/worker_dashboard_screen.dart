import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'worker_booking_detail_screen.dart';
import 'worker_kyc_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'work_history_screen.dart';
import 'bookings_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isOnline = false;
  Timer? _locationTimer;
  Timer? _refreshTimer;
  double _mockLat = 13.0827;
  double _mockLng = 80.2707;
  final List<int> _notifiedPendingIds = [];
  bool _processingAction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      setState(() {
        _isOnline = user?.status == 'active';
      });
      _loadData();
      if (_isOnline) {
        _startLocationSharing();
      }

      // Auto refresh dashboard every 8 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
        if (mounted) {
          _loadData();
        }
      });
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _checkNewPendingOrders() {
    if (!mounted) return;
    final bookings = context.read<BookingProvider>().bookings;
    final pending = bookings.where((b) => b.status == 'pending').toList();
    if (pending.isNotEmpty) {
      bool hasNew = false;
      for (final b in pending) {
        if (!_notifiedPendingIds.contains(b.id)) {
          _notifiedPendingIds.add(b.id);
          hasNew = true;
        }
      }
      if (hasNew) {
        HapticFeedback.vibrate();
        SystemSound.play(SystemSoundType.click);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.notification_important_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🔔 NEW JOB REQUEST RECEIVED! CHECK BELOW.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.zomatoRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _loadData() {
    context.read<AuthProvider>().reloadProfile();
    context.read<BookingProvider>().loadBookings().then((_) {
      _checkNewPendingOrders();
    });
  }

  void _startLocationSharing() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLocation();
    });
  }

  void _stopLocationSharing() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _updateLocation() async {
    if (!_isOnline) return;

    final user = context.read<AuthProvider>().user;
    final api = context.read<ApiService>();
    double lat = _mockLat;
    double lng = _mockLng;

    try {
      final position = await _determinePosition();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;

        if (user?.city?.toLowerCase() == 'chennai') {
          final distToChennai = (lat - 13.0827).abs() + (lng - 80.2707).abs();
          if (distToChennai > 0.5) {
            if (lat >= 12.0 && lat <= 14.0 && lng >= 77.0 && lng <= 79.0) {
              lat = 13.0827 + (lat - 12.9716);
              lng = 80.2707 + (lng - 77.5946);
            } else {
              lat = 13.0827;
              lng = 80.2707;
            }
          }
        }

        _mockLat = lat;
        _mockLng = lng;
      } else {
        final random = Random();
        _mockLat += (random.nextDouble() - 0.5) * 0.001;
        _mockLng += (random.nextDouble() - 0.5) * 0.001;
        lat = _mockLat;
        lng = _mockLng;
      }
    } catch (_) {
      final random = Random();
      _mockLat += (random.nextDouble() - 0.5) * 0.001;
      _mockLng += (random.nextDouble() - 0.5) * 0.001;
      lat = _mockLat;
      lng = _mockLng;
    }

    try {
      final pincode = user?.pincode ?? (user?.city?.toLowerCase() == 'chennai' ? '600001' : '560001');
      await api.updateWorkerLocation(lat, lng, pincode: pincode);
    } catch (_) {}
  }

  Future<void> _toggleOnlineStatus(bool online) async {
    setState(() {
      _isOnline = online;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateWorkerProfile(status: online ? 'active' : 'inactive');

    if (!mounted) return;

    if (ok) {
      if (online) {
        _startLocationSharing();
        _updateLocation();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are now Online and receiving job requests')),
        );
      } else {
        _stopLocationSharing();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are now Offline')),
        );
      }
    } else {
      setState(() {
        _isOnline = !online;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to update status')),
      );
    }
  }

  Future<void> _updateJobStatus(int bookingId, String newStatus) async {
    if (_processingAction) return;
    setState(() {
      _processingAction = true;
    });

    try {
      final api = context.read<ApiService>();
      await api.updateBookingStatus(bookingId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'confirmed' ? 'Job Accepted Successfully! 🎉' : 'Job Request Rejected'),
            backgroundColor: newStatus == 'confirmed' ? Colors.green.shade700 : AppTheme.zomatoRed,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Error updating job: $e'),
            backgroundColor: AppTheme.zomatoRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingAction = false;
        });
      }
    }
  }

  String _timeFmt(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookingProv = context.watch<BookingProvider>();
    final user = auth.user;
    final kyc = user?.kycStatus ?? 'not_submitted';

    final allBookings = bookingProv.bookings;
    final pendingBookings = allBookings.where((b) => b.status == 'pending').toList();
    final upcomingBookings = allBookings.where((b) => b.status == 'confirmed' || b.status == 'in_progress').toList();
    final completedBookings = allBookings.where((b) => b.status == 'completed').toList();

    // Today's stats calculation
    final today = DateTime.now();
    final todayBookings = allBookings.where((b) =>
        b.createdAt.year == today.year &&
        b.createdAt.month == today.month &&
        b.createdAt.day == today.day).toList();
    
    final todayCompleted = todayBookings.where((b) => b.status == 'completed').toList();
    final todayEarnings = todayCompleted.fold<double>(0, (sum, b) => sum + b.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: const Color(0xFF0F172A),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ─── 0. TOP LOCATION & NOTIFICATION BELL ICON BAR ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(builder: (ctx) {
                        final userCity = user?.city;
                        return Text(
                          (userCity != null && userCity.isNotEmpty) ? '$userCity, Tamil Nadu' : 'Madurai, Tamil Nadu',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        );
                      }),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF0F172A)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 22),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── 1. TOP ONLINE / OFFLINE TOGGLE CARD (Matching Image 2) ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Light Grey rounded pill card
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'You are Online' : 'You are Offline',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isOnline ? 'Receiving job requests actively' : 'Go Online to receive job requests',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.95,
                      child: Switch(
                        value: _isOnline,
                        onChanged: (val) => _toggleOnlineStatus(val),
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF16A34A),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── 2. NEW JOB REQUESTS SECTION ───
              const Text(
                'New Job Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 14),

              if (pendingBookings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_rounded, size: 36, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 8),
                        Text(
                          _isOnline
                              ? 'No new job requests right now.'
                              : 'Go Online to start receiving incoming job requests.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: pendingBookings.map((b) => _buildNewJobRequestCard(b)).toList(),
                ),

              const SizedBox(height: 28),

              // ─── 3. TODAY'S OVERVIEW SECTION ───
              const Text(
                "Today's Overview",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 14),

              // Summary Grid Cards (Earnings & Jobs Completed)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Earnings',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${todayEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jobs Completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${todayCompleted.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ─── 4. UPCOMING JOBS SECTION ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Jobs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (upcomingBookings.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BookingsScreen()),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              if (upcomingBookings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.calendar_month_rounded, size: 36, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 8),
                        Text(
                          'No active or upcoming jobs scheduled.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: upcomingBookings.map((b) => _buildUpcomingJobCard(b)).toList(),
                ),

              const SizedBox(height: 24),

              // ─── 5. KYC WIZARD CARD (If not approved) ───
              if (kyc != 'approved') _buildKycWizard(kyc),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NEW JOB REQUEST CARD COMPONENT (Matching Image 2 Design) ───
  Widget _buildNewJobRequestCard(BookingItem booking) {
    final locationText = booking.address != null && booking.address!.isNotEmpty
        ? booking.address!
        : 'Anna Nagar, Madurai';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Avatar, Service Title, Arrow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.home_repair_service_rounded, size: 24, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName ?? 'Plumbing Service',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.notes != null && booking.notes!.isNotEmpty
                          ? booking.notes!
                          : 'General Inspection & Repair',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkerBookingDetailScreen(bookingId: booking.id),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pricing Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '₹${booking.amount > 0 ? booking.amount.toStringAsFixed(0) : '200'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'visiting',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Text(
                '₹${booking.amount > 0 ? (booking.amount * 1.2).toStringAsFixed(0) : '2500'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons Row (Reject & Accept)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _processingAction ? null : () => _updateJobStatus(booking.id, 'cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _processingAction ? null : () => _updateJobStatus(booking.id, 'confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15), // Vibrant Yellow Accent Button
                    foregroundColor: const Color(0xFF0F172A),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── UPCOMING JOB CARD COMPONENT (Matching Image 2 Design) ───
  Widget _buildUpcomingJobCard(BookingItem booking) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkerBookingDetailScreen(bookingId: booking.id),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.build_rounded, size: 22, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceName ?? 'AC Service',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeFmt(booking.scheduledAt ?? booking.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeFmt(booking.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.status == 'in_progress' ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status == 'in_progress' ? 'In Progress' : 'Active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: booking.status == 'in_progress' ? const Color(0xFFD97706) : const Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycWizard(String status) {
    final steps = ['Registered', 'Uploaded', 'Under Review', 'Active'];
    int currentStep = 0;
    bool isRejected = status == 'rejected';

    if (status == 'pending') {
      currentStep = 2;
    } else if (status == 'approved') {
      currentStep = 3;
    } else if (isRejected) {
      currentStep = 2;
    } else {
      currentStep = 1;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'KYC ACTIVATION STATUS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.1),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final stepActive = index <= currentStep;
              final isLast = index == steps.length - 1;
              final stepColor = isRejected && index == 2
                  ? AppTheme.zomatoRed
                  : stepActive
                      ? AppTheme.olive
                      : Colors.grey.shade200;

              return Expanded(
                flex: isLast ? 0 : 1,
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: stepActive ? stepColor.withValues(alpha: 0.12) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stepActive ? stepColor : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isRejected && index == 2
                                ? const Icon(Icons.close_rounded, size: 14, color: AppTheme.zomatoRed)
                                : stepActive && index < currentStep
                                    ? Icon(Icons.check_rounded, size: 14, color: stepColor)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: stepActive ? stepColor : Colors.grey.shade400,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          steps[index],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: stepActive ? FontWeight.bold : FontWeight.w500,
                            color: stepActive ? Colors.black87 : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
                          color: index < currentStep ? AppTheme.olive : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          if (status != 'approved') ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isRejected ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: isRejected ? AppTheme.zomatoRed : AppTheme.olive,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRejected
                        ? 'Verification failed. Click below to re-submit your documents.'
                        : status == 'pending'
                            ? 'Admin is actively reviewing your KYC documents.'
                            : 'Submit your KYC documents to unlock your profile.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            if (status == 'not_submitted' || isRejected) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WorkerKycScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Upload KYC Documents',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
