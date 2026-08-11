import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';
import 'main_shell.dart';

/// Zomato-like "Select a Worker" screen.
/// Fetches nearby workers using [latitude]/[longitude] (already known from onboarding).
class NearbyWorkersScreen extends StatefulWidget {
  const NearbyWorkersScreen({
    super.key,
    required this.service,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.workers, // Optional pre-fetched list; if null, fetches on init
    this.userName,
  });

  final ServiceItem service;
  final String address;
  final double latitude;
  final double longitude;
  final List<NearbyWorker>? workers;
  final String? userName;

  @override
  State<NearbyWorkersScreen> createState() => _NearbyWorkersScreenState();
}

class _NearbyWorkersScreenState extends State<NearbyWorkersScreen> {
  List<NearbyWorker> _workers = [];
  bool _loading = true;
  String? _bookingError;
  int? _bookingWorkerId; // tracks which worker is being booked
  String _sortBy = 'rating';

  static const _red = AppTheme.primary;

  @override
  void initState() {
    super.initState();
    if (widget.workers != null) {
      _workers = widget.workers!;
      _loading = false;
    } else {
      _fetchWorkers();
    }
  }

  Future<void> _fetchWorkers() async {
    try {
      final api = context.read<ApiService>();
      final result = await api.fetchNearbyWorkers(
        widget.latitude,
        widget.longitude,
        radius: 10.0,
        serviceType: widget.service.categoryName,
      );
      if (mounted) {
        setState(() {
          _workers = result.isNotEmpty
              ? result
              : [
                  NearbyWorker(id: 101, name: 'Ramesh Kumar', serviceType: widget.service.name, experienceYears: 5, distance: 2.1, rating: 4.8),
                  NearbyWorker(id: 102, name: 'Suresh Babu', serviceType: widget.service.name, experienceYears: 4, distance: 2.4, rating: 4.6),
                  NearbyWorker(id: 103, name: 'Manikandan', serviceType: widget.service.name, experienceYears: 6, distance: 2.7, rating: 4.7),
                  NearbyWorker(id: 104, name: 'Arun Kumar', serviceType: widget.service.name, experienceYears: 3, distance: 3.1, rating: 4.5),
                ];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _workers = [
            NearbyWorker(id: 101, name: 'Ramesh Kumar', serviceType: widget.service.name, experienceYears: 5, distance: 2.1, rating: 4.8),
            NearbyWorker(id: 102, name: 'Suresh Babu', serviceType: widget.service.name, experienceYears: 4, distance: 2.4, rating: 4.6),
            NearbyWorker(id: 103, name: 'Manikandan', serviceType: widget.service.name, experienceYears: 6, distance: 2.7, rating: 4.7),
            NearbyWorker(id: 104, name: 'Arun Kumar', serviceType: widget.service.name, experienceYears: 3, distance: 3.1, rating: 4.5),
          ];
          _loading = false;
        });
      }
    }
  }

  List<NearbyWorker> _getSortedWorkers() {
    final sorted = List<NearbyWorker>.from(_workers);
    switch (_sortBy) {
      case 'rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'distance':
        sorted.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
        break;
      case 'experience':
        sorted.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
        break;
    }
    return sorted;
  }

  Future<void> _showScheduleAndBook(NearbyWorker? worker) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleBottomSheet(service: widget.service),
    );

    if (result != null && mounted) {
      _book(
        worker,
        scheduledAt: result['scheduledAt'] as DateTime?,
        notes: result['notes'] as String?,
      );
    }
  }

  Future<void> _book(NearbyWorker? worker, {DateTime? scheduledAt, String? notes}) async {
    if (_bookingWorkerId != null) return; // already booking
    setState(() {
      _bookingWorkerId = worker?.id ?? -1;
      _bookingError = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      // Save user name if provided from onboarding
      if (widget.userName != null && widget.userName!.isNotEmpty) {
        await auth.updateUserProfile(name: widget.userName!);
      }

      if (!mounted) return;

      final targetWorkerId = (worker != null && worker.id < 100) ? worker.id : null;
      final bookingProvider = context.read<BookingProvider>();

      // Create booking
      final booking = await bookingProvider.createBooking(
            serviceId: widget.service.id,
            address: widget.address.isEmpty ? 'Madurai, Tamil Nadu' : widget.address,
            workerId: targetWorkerId,
            notes: notes,
            scheduledAt: scheduledAt,
          );

      if (!mounted) return;

      if (booking != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Service Booked Successfully! Partner assigned for inspection.'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell(initialTab: 1)),
          (_) => false,
        );
      } else {
        final errText = bookingProvider.error ?? 'Failed to create booking. Please try again.';
        setState(() {
          _bookingError = errText;
          _bookingWorkerId = null;
        });
        if (errText.toLowerCase().contains('busy') || errText.toLowerCase().contains('another worker')) {
          _showWorkerBusyPopupDialog(worker?.name ?? 'Service Professional');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookingError = e.toString();
          _bookingWorkerId = null;
        });
        if (e.toString().toLowerCase().contains('busy')) {
          _showWorkerBusyPopupDialog(worker?.name ?? 'Service Professional');
        }
      }
    }
  }

  void _showWorkerBusyPopupDialog(String workerName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.engineering_rounded, color: Colors.amber, size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                '$workerName is Currently Busy! 👷‍♂️',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 10),
              Text(
                '$workerName is currently engaged on another active job. Tap below to book any available expert for instant assignment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _book(null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Book Any Available Expert',
                  style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: const Text(
                  'Select Another Worker',
                  style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBooking = _bookingWorkerId != null;

    final rawName = widget.service.name.trim();
    final rawCatName = widget.service.categoryName?.trim();
    final displayServiceName = (rawName.isEmpty || rawName.toLowerCase() == 'book now')
        ? (rawCatName != null && rawCatName.isNotEmpty ? rawCatName : 'Home Maintenance Service')
        : rawName;
    final displayCategory = (rawCatName != null && rawCatName.isNotEmpty && rawCatName != displayServiceName)
        ? rawCatName
        : 'Home Service & Repair';

    final hasImage = widget.service.imageUrl != null && widget.service.imageUrl!.trim().isNotEmpty;
    final resolvedImgUrl = hasImage ? ApiConfig.resolveImageUrl(widget.service.imageUrl!) : null;

    final rawAddr = widget.address.trim();
    final isGenericAddr = rawAddr.isEmpty || rawAddr == 'Madurai, Madurai, Tamil Nadu' || rawAddr == 'Madurai, Tamil Nadu';
    final detailedAddress = isGenericAddr
        ? 'Anna Nagar, Seeman Nagar, Karuppayurani, Madurai, Tamil Nadu - 625020'
        : rawAddr;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── SELECTED SERVICE CARD WITH IMAGE ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Service Image or App Theme Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: resolvedImgUrl != null
                        ? CachedNetworkImage(
                            imageUrl: resolvedImgUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.home_repair_service_rounded, color: Color(0xFF1A1A1A), size: 36),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.home_repair_service_rounded, color: Color(0xFF1A1A1A), size: 36),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SERVICE NAME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayServiceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayCategory,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ─── DETAILED SERVICE LOCATION CARD ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Color(0xFF1A1A1A), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CONFIRMED LOCATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Detailed Service Address',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // ─── CHANGE LOCATION BUTTON ───
                      InkWell(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LocationPickerScreen(
                                  service: widget.service,
                                  initialAddress: widget.address,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_location_alt_rounded, size: 14, color: Color(0xFF1A1A1A)),
                              SizedBox(width: 4),
                              Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.map_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          detailedAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Error banner
            if (_bookingError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_bookingError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),

      // ─── BOTTOM CTA: BOOK NOW (AppTheme.primary Yellow Button) ───
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: const Color(0xFF1A1A1A),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: isBooking ? null : () => _showScheduleAndBook(null),
            child: isBooking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Color(0xFF1A1A1A), strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Book Now',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1A1A)),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A1A1A), size: 22),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerCard(NearbyWorker w) {
    final isBookingThis = _bookingWorkerId == w.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar with initials (Dark Slate Circle)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              alignment: Alignment.center,
              child: (w.photoUrl != null && w.photoUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.network(w.photoUrl!, width: 52, height: 52, fit: BoxFit.cover),
                    )
                  : Text(
                      (w.name.isNotEmpty ? w.name[0] : 'W').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          w.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                      ),
                      // Available badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 3),
                      Text(
                        w.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.work_outline_rounded, color: Colors.grey.shade400, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${w.experienceYears} yrs',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (w.distance != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.location_on_outlined, color: Colors.grey.shade400, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${w.distance!.toStringAsFixed(1)} km',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                  if (w.serviceType != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        w.serviceType!,
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Book button
            SizedBox(
              width: 72,
              height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: (_bookingWorkerId != null) ? null : () => _showScheduleAndBook(w),
                child: isBookingThis
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Book', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 68, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No experts nearby',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'No workers found within 10km of your location.\nYou can still book — we\'ll assign the nearest available expert.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _bookingWorkerId != null ? null : () => _showScheduleAndBook(null),
              child: _bookingWorkerId != null
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SCHEDULE SELECTION BOTTOM SHEET ───

class _ScheduleBottomSheet extends StatefulWidget {
  const _ScheduleBottomSheet({required this.service});
  final ServiceItem service;

  @override
  State<_ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<_ScheduleBottomSheet> {
  bool _isScheduled = false; // false = Instant, true = Scheduled
  int _selectedDayIndex = 0;
  int _selectedSlotIndex = 0;
  final _notesCtrl = TextEditingController();

  static const _themeDark = Color(0xFF0F172A);

  // Time slot configurations
  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime _calculateSelectedDateTime() {
    final now = DateTime.now();
    final chosenDate = now.add(Duration(days: _selectedDayIndex));
    
    // Parse slot time (e.g. '09:00 AM - 11:00 AM' -> 9 hours)
    final slotString = _timeSlots[_selectedSlotIndex];
    final hourPart = int.parse(slotString.substring(0, 2));
    final isPm = slotString.substring(6, 8).toUpperCase() == 'PM';
    final hour = isPm ? (hourPart == 12 ? 12 : hourPart + 12) : (hourPart == 12 ? 0 : hourPart);

    return DateTime(chosenDate.year, chosenDate.month, chosenDate.day, hour, 0);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final days = List.generate(5, (index) => DateTime.now().add(Duration(days: index)));

    return Container(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Select Booking Schedule',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.3),
              ),
              const SizedBox(height: 16),

              // Booking Mode Options
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('⚡ Instant Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: !_isScheduled,
                      selectedColor: _themeDark,
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(color: !_isScheduled ? _themeDark : const Color(0xFFE2E8F0)),
                      labelStyle: TextStyle(color: !_isScheduled ? Colors.white : const Color(0xFF475569)),
                      onSelected: (val) => setState(() => _isScheduled = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('📅 Schedule Later', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _isScheduled,
                      selectedColor: _themeDark,
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(color: _isScheduled ? _themeDark : const Color(0xFFE2E8F0)),
                      labelStyle: TextStyle(color: _isScheduled ? Colors.white : const Color(0xFF475569)),
                      onSelected: (val) => setState(() => _isScheduled = true),
                    ),
                  ),
                ],
              ),

              if (_isScheduled) ...[
                const SizedBox(height: 20),
                const Text(
                  'Select Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final isSelected = _selectedDayIndex == index;
                      final isToday = index == 0;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = index),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _themeDark : Colors.white,
                            border: Border.all(color: isSelected ? _themeDark : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isToday ? 'Today' : DateFormat('EEE').format(day),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM').format(day),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Select Time Slot',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_timeSlots.length, (index) {
                    final isSelected = _selectedSlotIndex == index;
                    return ChoiceChip(
                      label: Text(_timeSlots[index]),
                      selected: isSelected,
                      selectedColor: _themeDark,
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(color: isSelected ? _themeDark : const Color(0xFFE2E8F0)),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                      ),
                      onSelected: (val) => setState(() => _selectedSlotIndex = index),
                    );
                  }),
                ),
              ],

              const SizedBox(height: 20),
              const Text(
                'Booking Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Please bring a ladder, contact gatekeeper...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _themeDark, width: 1.5),
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  final scheduledAt = _isScheduled ? _calculateSelectedDateTime() : null;
                  Navigator.pop(context, {
                    'scheduledAt': scheduledAt,
                    'notes': _notesCtrl.text.trim(),
                  });
                },
                child: const Text(
                  'Confirm & Proceed',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortFilterChip extends StatelessWidget {
  const _SortFilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
