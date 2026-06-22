import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'worker_booking_detail_screen.dart';
import 'worker_kyc_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isOnline = false;
  String _activeTab = 'active'; // 'active' or 'completed'
  Timer? _locationTimer;
  double _mockLat = 12.9716; // Simulated Bangalore coordinates
  double _mockLng = 77.5946;

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
    // Reload worker profile to check latest KYC / online status
    context.read<AuthProvider>().reloadProfile();
    // Load bookings
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

  Future<void> _updateLocation() async {
    if (!_isOnline) return;
    
    // Add small random offset to simulate movement
    final random = Random();
    _mockLat += (random.nextDouble() - 0.5) * 0.001;
    _mockLng += (random.nextDouble() - 0.5) * 0.001;

    try {
      final api = context.read<ApiService>();
      await api.updateWorkerLocation(_mockLat, _mockLng, pincode: '560001');
    } catch (_) {
      // Fail silently in background
    }
  }

  Future<void> _toggleOnlineStatus(bool online) async {
    setState(() {
      _isOnline = online;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateWorkerProfile(status: online ? 'active' : 'inactive');

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
      // Revert if error
      setState(() {
        _isOnline = !online;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to update status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookingProv = context.watch<BookingProvider>();

    final user = auth.user;
    final kyc = user?.kycStatus ?? 'not_submitted';

    // Filter bookings based on tab selection
    final list = bookingProv.bookings.where((b) {
      if (_activeTab == 'active') {
        return b.status == 'pending' || b.status == 'confirmed' || b.status == 'in_progress';
      } else {
        return b.status == 'completed' || b.status == 'cancelled';
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: Colors.black,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Online / Offline Toggle Card
              _buildStatusCard(kyc == 'approved'),

              const SizedBox(height: 20),

              // KYC onboarding banner
              _buildKycBanner(kyc),

              const SizedBox(height: 24),

              // Jobs Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assigned Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    _activeTab == 'active' ? 'No active jobs assigned' : 'No completed jobs yet',
                    style: TextStyle(color: Colors.grey.shade500),
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
                    return BookingCard(
                      booking: item,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WorkerBookingDetailScreen(bookingId: item.id),
                          ),
                        ).then((_) => _loadData());
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isVerified) {
    if (!isVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: const [
            Icon(Icons.lock_outline_rounded, color: Colors.black),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verification required to toggle online availability status.',
                style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'Online Status' : 'Offline Status',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      _isOnline ? 'Accepting new jobs' : 'Not receiving jobs',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            Switch(
              value: _isOnline,
              onChanged: _toggleOnlineStatus,
              activeColor: Colors.black,
              activeTrackColor: Colors.grey.shade300,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycBanner(String kycStatus) {
    if (kycStatus == 'approved') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.verified_user_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verified Service Partner',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (kycStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Identity Verification Pending',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin is reviewing your KYC documents.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.black, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Required',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kycStatus == 'rejected'
                            ? 'Your documents were rejected. Please correction-upload.'
                            : 'Upload your ID and bank details to start earning.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
          color: active ? Colors.black : Colors.transparent,
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
