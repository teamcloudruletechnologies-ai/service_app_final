import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

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
  final ApiService _api = ApiService();
  bool _isOnline = false;
  String _activeTab = 'active';
  Timer? _locationTimer;
  Timer? _refreshTimer;
  double _mockLat = 13.0827;
  double _mockLng = 80.2707;

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

      // Auto refresh dashboard every 10 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
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

  final List<int> _notifiedPendingIds = [];

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
                    '🔔 NEW JOB REQUEST RECEIVED! CHECK ORDERS.',
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
          const SnackBar(content: Text('You are now Online and receiving jobs')),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
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
    final auth = context.watch<AuthProvider>();
    final bookingProv = context.watch<BookingProvider>();
    final user = auth.user;
    final kyc = user?.kycStatus ?? 'not_submitted';

    final allBookings = bookingProv.bookings;
    final activeBookings = allBookings.where((b) =>
        b.status == 'pending' || b.status == 'confirmed' || b.status == 'in_progress').toList();
    final historyBookings = allBookings.where((b) =>
        b.status == 'completed' || b.status == 'cancelled').toList();

    final list = _activeTab == 'active' ? activeBookings : historyBookings;

    // Today's stats
    final today = DateTime.now();
    final todayBookings = allBookings.where((b) =>
        b.createdAt.year == today.year &&
        b.createdAt.month == today.month &&
        b.createdAt.day == today.day).toList();
    final todayEarnings = todayBookings
        .where((b) => b.status == 'completed')
        .fold<double>(0, (sum, b) => sum + b.amount);

    return Scaffold(
      backgroundColor: AppTheme.milkWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppTheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ─── TOP HEADER BAR ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.sandal,
                          child: Text(
                            (user?.name.isNotEmpty == true ? user!.name[0] : 'W').toUpperCase(),
                            style: const TextStyle(color: AppTheme.matteBlack, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Service Partner',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.matteBlack,
                              ),
                            ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () => _toggleOnlineStatus(!_isOnline),
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isOnline ? Colors.green : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isOnline ? 'Active Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ), // Close InkWell
                Row(
                  children: [
                    // Online / Offline Switch Toggle
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _isOnline,
                          onChanged: (val) => _toggleOnlineStatus(val),
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppTheme.primary,
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(width: 2),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.matteBlack, size: 20),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── HERO WALLET BALANCE CARD ───
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WorkHistoryScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${todayEarnings.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'AJ Balance (Tap for History) →',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.sandal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 40,
                          color: AppTheme.sandal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── JOBS OVERVIEW SECTION ───
              const Text(
                'Jobs Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.matteBlack,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BookingsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${activeBookings.length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.matteBlack),
                            ),
                            const SizedBox(height: 4),
                            Text('Active Jobs', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BookingsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${activeBookings.where((b) => b.status == 'pending').length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.matteBlack),
                            ),
                            const SizedBox(height: 4),
                            Text('Pending Jobs', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => WorkHistoryScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${historyBookings.length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.matteBlack),
                            ),
                            const SizedBox(height: 4),
                            Text('Completed Jobs', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── MY EARNINGS SECTION ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Earnings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.matteBlack,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Text('Month', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                        Text(
                          '${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 7)))} - ${DateFormat('MMM d').format(DateTime.now())}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('${historyBookings.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Completed Jobs', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.grey.shade200),
                        Column(
                          children: [
                            Text('₹${todayEarnings.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            const SizedBox(height: 2),
                            Text('Job Earnings', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── PAYMENTS HISTORY SECTION ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Payments History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.matteBlack,
                    ),
                  ),
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (historyBookings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'No payment transactions recorded yet.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                Column(
                  children: historyBookings.map((b) {
                    final dateStr = DateFormat('dd MMM, hh:mm a').format(b.scheduledAt ?? b.createdAt);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildPaymentHistoryItem(
                        b.userName ?? 'Customer',
                        'Job #${b.id}',
                        '₹${b.amount.toStringAsFixed(2)}',
                        dateStr,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryItem(String name, String jobId, String amount, String date) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.sandal,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.matteBlack),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.matteBlack),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$jobId • $date',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineCard(bool isVerified, int todayCount, double todayEarn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: !isVerified
            ? const Color(0xFFF3F4F6)
            : _isOnline
                ? AppTheme.olive
                : const Color(0xFF6B7280),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isOnline && isVerified ? AppTheme.olive : Colors.black).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: !isVerified
                          ? Colors.grey
                          : _isOnline
                              ? Colors.white
                              : Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !isVerified
                            ? 'Verification Required'
                            : _isOnline
                                ? 'Online - Accepting jobs'
                                : 'Offline',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: !isVerified || !_isOnline ? Colors.white : Colors.white,
                        ),
                      ),
                      if (isVerified)
                        Text(
                          _isOnline ? 'You will receive new orders' : 'Turn on to receive orders',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _isOnline,
                onChanged: isVerified ? _toggleOnlineStatus : null,
                activeColor: AppTheme.olive,
                activeTrackColor: Colors.white.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
          if (isVerified) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$todayCount',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'jobs today',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Column(
                    children: [
                      Text(
                        '₹${todayEarn.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'earned today',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKycWizard(String status) {
    final steps = ['Registered', 'Uploaded', 'Under Review', 'Active'];
    int currentStep = 0;
    bool isRejected = status == 'rejected';

    if (status == 'pending') {
      currentStep = 2; // Under review
    } else if (status == 'approved') {
      currentStep = 3; // Active
    } else if (isRejected) {
      currentStep = 2; // Under review failed
    } else {
      currentStep = 1; // Not submitted yet
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'KYC ACTIVATION STATUS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
          const SizedBox(height: 16),
          // Stepper Row
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
                            color: stepActive ? stepColor.withOpacity(0.12) : Colors.transparent,
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
                            : 'Submit Aadhaar Card and Bank Details to unlock your profile.',
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
                  minimumSize: const Size.fromHeight(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildOrderCard(dynamic item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkerBookingDetailScreen(bookingId: item.id),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(item.status),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(item.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  _timeAgo(item.createdAt),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.serviceName ?? 'Service #${item.serviceId}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  item.userName ?? 'Customer',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (item.address != null && item.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${item.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _TabBtn(
            label: 'Active',
            active: _activeTab == 'active',
            onTap: () => setState(() => _activeTab = 'active'),
          ),
          _TabBtn(
            label: 'History',
            active: _activeTab == 'completed',
            onTap: () => setState(() => _activeTab = 'completed'),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
