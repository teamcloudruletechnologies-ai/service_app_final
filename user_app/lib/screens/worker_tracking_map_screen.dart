import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../theme/app_theme.dart';

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

      // Move map to center on worker
      if (result.workerLat != null && result.workerLng != null) {
        final pos = LatLng(result.workerLat!, result.workerLng!);
        _mapController.move(pos, _mapController.camera.zoom);
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadData(),
          )
        ],
      ),
      body: _loading && _booking == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadData(),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                          child: const Text('Retry'),
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
                                          color: AppTheme.secondary.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.person_pin_circle, color: AppTheme.secondary, size: 36),
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
                                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))
                                          ],
                                          border: Border.all(color: AppTheme.primary, width: 2),
                                        ),
                                        child: const Icon(Icons.engineering_rounded, color: AppTheme.primary, size: 28),
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
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'LIVE TRACKING',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _booking!.workerName ?? 'Assigned Partner',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _booking!.serviceName ?? 'Professional Service',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'in_progress' ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: status == 'in_progress' ? Colors.purple : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // OTP Banner
          if ((status == 'confirmed' || status == 'in_progress') && otp != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status == 'confirmed' ? 'Start Verification OTP' : 'Completion Verification OTP',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status == 'confirmed'
                            ? 'Share this OTP with partner to start work'
                            : 'Share this OTP with partner when work is finished',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    otp,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.secondary,
                      letterSpacing: 2,
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
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
              if (_booking!.workerPhone != null && _booking!.workerPhone!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    // Quick contact placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${_booking!.workerPhone}...')),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 16, color: Colors.white),
                  label: const Text('Contact Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
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
