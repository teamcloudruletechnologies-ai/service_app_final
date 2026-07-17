import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isOnline = false;
  String _activeTab = 'active';
  Timer? _locationTimer;
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
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    context.read<AuthProvider>().reloadProfile();
    context.read<BookingProvider>().loadBookings();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppTheme.olive,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Greeting
              Text(
                '${_greeting()}, ${user?.name ?? 'Partner'}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),

              // Online/Offline Toggle Card
              _buildOnlineCard(kyc == 'approved', todayBookings.length, todayEarnings),
              const SizedBox(height: 16),

              // KYC Banner
              _buildKycBanner(kyc),
              const SizedBox(height: 24),

              // Active Orders Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Active Orders',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 8),
                      if (activeBookings.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.zomatoRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${activeBookings.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  _buildTabToggle(),
                ],
              ),
              const SizedBox(height: 12),

              // Bookings List
              if (bookingProv.loading)
                const SizedBox(height: 150, child: LoadingView(message: 'Loading bookings...'))
              else if (list.isEmpty)
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _activeTab == 'active' ? Icons.inbox_outlined : Icons.history_outlined,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeTab == 'active' ? 'No active jobs assigned' : 'No completed jobs yet',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildOrderCard(item);
                  },
                ),
            ],
          ),
        ),
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

  Widget _buildKycBanner(String kycStatus) {
    if (kycStatus == 'approved') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.olive.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: const [
            Icon(Icons.verified_user_rounded, color: AppTheme.olive, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verified Service Partner',
                style: TextStyle(color: AppTheme.olive, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (kycStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.sandal),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.olive),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Identity Verification Pending',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin is reviewing your KYC documents.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.zomatoRed.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.zomatoRed, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Required',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kycStatus == 'rejected'
                          ? 'Your documents were rejected. Please re-upload.'
                          : 'Upload your ID and bank details to start earning.',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkerKycScreen()),
              ).then((_) => _loadData());
            },
            child: const Text('Start Verification Onboarding'),
          ),
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
