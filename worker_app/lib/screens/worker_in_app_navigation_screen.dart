import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class WorkerInAppNavigationScreen extends StatefulWidget {
  const WorkerInAppNavigationScreen({
    super.key,
    required this.bookingId,
    required this.customerName,
    required this.customerAddress,
    this.initialLat,
    this.initialLng,
  });

  final int bookingId;
  final String customerName;
  final String customerAddress;
  final double? initialLat;
  final double? initialLng;

  @override
  State<WorkerInAppNavigationScreen> createState() => _WorkerInAppNavigationScreenState();
}

class _WorkerInAppNavigationScreenState extends State<WorkerInAppNavigationScreen> {
  final MapController _mapController = MapController();
  LatLng _workerPos = const LatLng(13.0827, 80.2707); // Default Chennai
  LatLng? _customerPos;

  bool _loading = true;
  String? _error;
  double _distanceKm = 0.0;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _initNavigation();
  }

  Future<void> _initNavigation() async {
    setState(() => _loading = true);

    try {
      // 1. Get worker position
      Position? position;
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
        }
      } catch (_) {}

      if (position != null) {
        _workerPos = LatLng(position.latitude, position.longitude);
      }

      // 2. Geocode customer address
      LatLng? custLatLng;
      if (widget.initialLat != null && widget.initialLng != null && widget.initialLat != 0) {
        custLatLng = LatLng(widget.initialLat!, widget.initialLng!);
      } else {
        custLatLng = await _geocodeAddress(widget.customerAddress);
      }

      if (custLatLng == null) {
        // Fallback offset slightly from worker position if geocoding yields no results
        custLatLng = LatLng(_workerPos.latitude + 0.015, _workerPos.longitude + 0.015);
      }

      _customerPos = custLatLng;

      // 3. Calculate Distance
      const distanceCalc = Distance();
      _distanceKm = distanceCalc.as(LengthUnit.Kilometer, _workerPos, _customerPos!) ?? 0.0;

      // 4. Create simple route polyline
      _routePoints = [_workerPos, _customerPos!];

      setState(() => _loading = false);

      // Center map bounds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _customerPos != null) {
          final bounds = LatLngBounds.fromPoints([_workerPos, _customerPos!]);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Navigation setup error: $e';
          _loading = false;
        });
      }
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1');
      final res = await http.get(url, headers: {'User-Agent': 'UrbanWorkerApp/1.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigate to Booking #${widget.bookingId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_customerPos != null) {
                final bounds = LatLngBounds.fromPoints([_workerPos, _customerPos!]);
                _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ─── FREE OPENSTREETMAP ───
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _workerPos,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.urban.worker_app',
              ),
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.5,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Worker position pin
                  Marker(
                    point: _workerPos,
                    width: 44,
                    height: 44,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  // Customer destination pin
                  if (_customerPos != null)
                    Marker(
                      point: _customerPos!,
                      width: 48,
                      height: 48,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),

          // ─── BOTTOM NAVIGATION INFO DRAWER ───
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CUSTOMER DESTINATION',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.customerName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.sandal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_distanceKm.toStringAsFixed(1)} KM away',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.matteBlack),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.customerAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('Back to Booking Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
