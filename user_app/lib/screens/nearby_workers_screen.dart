import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

/// Zomato-like "Select a Worker" screen.
/// Fetches nearby workers using [latitude]/[longitude] (already known from onboarding).
/// Book button → PaymentScreen directly.
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

  static const _red = Color(0xFFE23744);

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
      if (mounted) setState(() { _workers = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _book(NearbyWorker? worker) async {
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
          );

      if (!mounted) return;

      if (booking != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
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
                        itemCount: _workers.length,
                        itemBuilder: (context, index) => _buildWorkerCard(_workers[index]),
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
            onPressed: _bookingWorkerId != null ? null : () => _book(null),
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
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: _red.withValues(alpha: 0.08),
              backgroundImage: (w.photoUrl != null && w.photoUrl!.isNotEmpty)
                  ? NetworkImage(w.photoUrl!)
                  : null,
              child: (w.photoUrl == null || w.photoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: _red, size: 26)
                  : null,
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
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
                  if (w.serviceType != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        w.serviceType!,
                        style: TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
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
                onPressed: (_bookingWorkerId != null) ? null : () => _book(w),
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
              onPressed: _bookingWorkerId != null ? null : () => _book(null),
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
