import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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

  static const _red = Color(0xFF4A5343);

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
          _workers = result;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

      // Create booking
      final booking = await context.read<BookingProvider>().createBooking(
            serviceId: widget.service.id,
            address: widget.address,
            workerId: worker?.id,
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
        setState(() {
          _bookingError = 'Failed to create booking. Please try again.';
          _bookingWorkerId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookingError = e.toString();
          _bookingWorkerId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.service.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── CONFIRMED LOCATION BAR (Zomato style) ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: _red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SERVICE LOCATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── SERVICE SUMMARY ───
          Container(
            color: const Color(0xFFFEF2F2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.home_repair_service, color: _red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.service.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── SORT/FILTER BAR ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Sort by:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 8),
                _SortFilterChip(
                  label: '⭐ Rating',
                  active: _sortBy == 'rating',
                  onTap: () => setState(() => _sortBy = 'rating'),
                ),
                const SizedBox(width: 6),
                _SortFilterChip(
                  label: '📍 Distance',
                  active: _sortBy == 'distance',
                  onTap: () => setState(() => _sortBy = 'distance'),
                ),
                const SizedBox(width: 6),
                _SortFilterChip(
                  label: '💼 Experience',
                  active: _sortBy == 'experience',
                  onTap: () => setState(() => _sortBy = 'experience'),
                ),
              ],
            ),
          ),

          // Error banner
          if (_bookingError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_bookingError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ),

          // ─── WORKERS SECTION HEADER ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  'AVAILABLE EXPERTS NEAR YOU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_workers.length} found',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ─── WORKER LIST ───
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _red))
                    : _workers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _getSortedWorkers().length,
                            itemBuilder: (context, index) => _buildWorkerCard(_getSortedWorkers()[index]),
                          ),
          ),
        ],
      ),
      // ─── BOTTOM: BOOK ANY WORKER CTA ───
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(color: _red, width: 1.5),
            ),
            onPressed: _bookingWorkerId != null ? null : () => _showScheduleAndBook(null),
            child: _bookingWorkerId == -1
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _red, strokeWidth: 2.5))
                : const Text(
                    'Book Any Available Expert',
                    style: TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 15),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar with initials
            CircleAvatar(
              radius: 28,
              backgroundColor: _red.withValues(alpha: 0.08),
              backgroundImage: (w.photoUrl != null && w.photoUrl!.isNotEmpty)
                  ? NetworkImage(w.photoUrl!)
                  : null,
              child: (w.photoUrl == null || w.photoUrl!.isEmpty)
                  ? Text(
                      (w.name.isNotEmpty ? w.name[0] : 'W').toUpperCase(),
                      style: const TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 20),
                    )
                  : null,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)),
                        ),
                      ),
                      // Available badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Available',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        w.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.work_outline, color: Colors.grey.shade400, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${w.experienceYears} yrs',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (w.distance != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.location_on, color: Colors.grey.shade400, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          '${w.distance!.toStringAsFixed(1)} km',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  if (w.serviceType != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        w.serviceType!,
                        style: TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Book button
            SizedBox(
              width: 68,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: (_bookingWorkerId != null) ? null : () => _showScheduleAndBook(w),
                child: isBookingThis
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  static const _red = Color(0xFF4A5343);

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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 16),

              // Booking Mode Options
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('⚡ Instant Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: !_isScheduled,
                      selectedColor: _red.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: !_isScheduled ? _red : Colors.grey.shade700),
                      onSelected: (val) => setState(() => _isScheduled = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('📅 Schedule Later', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _isScheduled,
                      selectedColor: _red.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: _isScheduled ? _red : Colors.grey.shade700),
                      onSelected: (val) => setState(() => _isScheduled = true),
                    ),
                  ),
                ],
              ),

              if (_isScheduled) ...[
                const SizedBox(height: 20),
                const Text(
                  'Select Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
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
                            color: isSelected ? _red : Colors.white,
                            border: Border.all(color: isSelected ? _red : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isToday ? 'Today' : DateFormat('EEE').format(day),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : Colors.grey.shade500,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM').format(day),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Color(0xFF111827),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
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
                      selectedColor: _red.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _red : Color(0xFF374151),
                      ),
                      onSelected: (val) => setState(() => _selectedSlotIndex = index),
                    );
                  }),
                ),
              ],

              const SizedBox(height: 20),
              const Text(
                'Booking Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Please bring a ladder, contact gatekeeper...',
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _red),
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE23744) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFFE23744) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF1A1A1A),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
