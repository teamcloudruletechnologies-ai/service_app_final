import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';

class WorkerTrackingMapScreen extends StatefulWidget {
  const WorkerTrackingMapScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<WorkerTrackingMapScreen> createState() => _WorkerTrackingMapScreenState();
}

class _WorkerTrackingMapScreenState extends State<WorkerTrackingMapScreen> {
  final MapController _mapController = MapController();
  Timer? _timer;
  bool _loading = true;
  String? _error;
  BookingItem? _booking;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadData(isSilent: true);
      }
    });
  }

  Future<void> _loadData({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final bookingProv = context.read<BookingProvider>();
    final result = await bookingProv.loadBookingDetail(widget.bookingId);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _booking = result;
        _loading = false;
        _lastUpdate = DateTime.now();
      });

      // Move map to center on worker safely
      if (result.workerLat != null && result.workerLng != null) {
        final pos = LatLng(result.workerLat!, result.workerLng!);
        try {
          _mapController.move(pos, 14.5);
        } catch (e) {
          // Ignore uninitialized map controller before mount
        }
      }
    } else {
      if (!isSilent) {
        setState(() {
          _error = 'Failed to load live tracking details.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final defaultUserLocation = LatLng(auth.latitude ?? 13.0827, auth.longitude ?? 80.2707);

    LatLng? userLocation;
    if (auth.latitude != null && auth.longitude != null) {
      userLocation = LatLng(auth.latitude!, auth.longitude!);
    }

    final workerLocation = (_booking?.workerLat != null && _booking?.workerLng != null)
        ? LatLng(_booking!.workerLat!, _booking!.workerLng!)
        : null;

    final mapCenter = workerLocation ?? userLocation ?? defaultUserLocation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Live Tracking',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.3),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            onPressed: () => _loadData(),
          )
        ],
      ),
      body: _loading && _booking == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadData(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Tracking Map Area
                    Expanded(
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: mapCenter,
                              initialZoom: 14.5,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.urban.service_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  // User Marker
                                  if (userLocation != null)
                                    Marker(
                                      point: userLocation,
                                      width: 45,
                                      height: 45,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF0F172A), size: 36),
                                      ),
                                    ),
                                  // Worker Marker
                                  if (workerLocation != null)
                                    Marker(
                                      point: workerLocation,
                                      width: 50,
                                      height: 50,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.20), blurRadius: 8, offset: const Offset(0, 3))
                                          ],
                                          border: Border.all(color: const Color(0xFF0F172A), width: 2.2),
                                        ),
                                        child: const Icon(Icons.engineering_rounded, color: Color(0xFF0F172A), size: 28),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          // Live Indicator / Status Bar overlay
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'LIVE TRACKING',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Information Sheet
                    _buildInfoPanel(context),
                  ],
                ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    if (_booking == null) return const SizedBox();

    final status = _booking!.status;
    final otp = _booking!.otp;

    Color statusBgColor;
    Color statusTextColor;

    switch (status) {
      case 'completed':
        statusBgColor = const Color(0xFFECFDF5);
        statusTextColor = const Color(0xFF059669);
        break;
      case 'in_progress':
        statusBgColor = const Color(0xFFF3E8FF);
        statusTextColor = const Color(0xFF7C3AED);
        break;
      case 'confirmed':
        statusBgColor = const Color(0xFFEFF6FF);
        statusTextColor = const Color(0xFF2563EB);
        break;
      default:
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFD97706);
        break;
    }

    final workerName = _booking!.workerName ?? 'Assigned Partner';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Worker details
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  workerName.trim().isNotEmpty ? workerName.trim()[0].toUpperCase() : 'W',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _booking!.serviceName ?? 'Professional Service',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // OTP Banner
          if ((status == 'confirmed' || status == 'in_progress') && otp != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.key_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status == 'confirmed' ? 'JOB START OTP' : 'JOB COMPLETION OTP',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status == 'confirmed'
                              ? 'Share with worker when they arrive'
                              : 'Share with worker when work finishes',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                    ),
                    child: Text(
                      otp,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 3.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Footer info / last update tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last updated: ${_lastUpdate.hour.toString().padLeft(2, '0')}:${_lastUpdate.minute.toString().padLeft(2, '0')}:${_lastUpdate.second.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
              ),
              if (_booking!.workerPhone != null && _booking!.workerPhone!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${_booking!.workerPhone}...', style: const TextStyle(fontWeight: FontWeight.w700)),
                        backgroundColor: const Color(0xFF0F172A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_rounded, size: 15, color: Colors.white),
                  label: const Text('Contact Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
