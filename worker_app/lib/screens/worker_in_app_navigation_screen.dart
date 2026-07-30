import 'dart:async';
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
  int _durationMins = 0;
  String _nextTurnInstruction = 'Follow indicated road path to destination';
  List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initNavigation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initNavigation() async {
    setState(() => _loading = true);

    try {
      // 1. Fetch current worker GPS location
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

      // 2. Geocode customer target address
      LatLng? custLatLng;
      if (widget.initialLat != null && widget.initialLng != null && widget.initialLat != 0) {
        custLatLng = LatLng(widget.initialLat!, widget.initialLng!);
      } else {
        custLatLng = await _geocodeAddress(widget.customerAddress);
      }

      if (custLatLng == null) {
        custLatLng = LatLng(_workerPos.latitude + 0.015, _workerPos.longitude + 0.015);
      }

      _customerPos = custLatLng;

      // 3. Fetch OSRM Road Driving Route
      await _fetchRoadRoute(_workerPos, _customerPos!);

      // 4. Start Live GPS Position Stream for continuous updates & auto-recalculation
      _startLivePositionStream();

      setState(() => _loading = false);

      // Fit map camera
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _customerPos != null) {
          final bounds = LatLngBounds.fromPoints([_workerPos, _customerPos!]);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
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

  Future<void> _fetchRoadRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0];
          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSecs = (route['duration'] as num).toDouble();

          final geometry = route['geometry'];
          final coords = geometry['coordinates'] as List;
          final points = coords.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

          // Extract turn instruction step if available
          String turnMsg = 'Follow road path to destination';
          try {
            final steps = route['legs'][0]['steps'] as List;
            if (steps.length > 1) {
              final step = steps[1];
              final maneuver = step['maneuver'];
              final type = maneuver['type'] ?? 'continue';
              final modifier = maneuver['modifier'] ?? '';
              final name = step['name'] ?? '';
              turnMsg = '${type.toUpperCase()} $modifier ${name.isNotEmpty ? "onto $name" : ""}';
            }
          } catch (_) {}

          setState(() {
            _routePoints = points;
            _distanceKm = distanceMeters / 1000;
            _durationMins = (durationSecs / 60).round();
            _nextTurnInstruction = turnMsg;
          });
          return;
        }
      }
    } catch (_) {}

    // Direct line fallback if OSRM is offline
    const distanceCalc = Distance();
    setState(() {
      _routePoints = [origin, destination];
      _distanceKm = distanceCalc.as(LengthUnit.Kilometer, origin, destination) ?? 0.0;
      _durationMins = (_distanceKm * 3).round();
    });
  }

  void _startLivePositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10 meters
      ),
    ).listen((pos) {
      if (!mounted || _customerPos == null) return;
      final newPos = LatLng(pos.latitude, pos.longitude);

      const distanceCalc = Distance();
      final movedMeters = distanceCalc.as(LengthUnit.Meter, _workerPos, newPos) ?? 0;

      setState(() {
        _workerPos = newPos;
      });

      // Move camera to center worker position
      _mapController.move(newPos, _mapController.camera.zoom);

      // Auto Recalculate route if worker moved > 30 meters
      if (movedMeters > 30) {
        _fetchRoadRoute(newPos, _customerPos!);
      }
    });
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

      // Fallback: strip door numbers / leading digits before first comma
      List<String> parts = address.split(',');
      if (parts.length > 1) {
        String fallbackAddr = parts.sublist(1).join(',').trim();
        final fbUrl = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(fallbackAddr)}&format=json&limit=1');
        final fbRes = await http.get(fbUrl, headers: {'User-Agent': 'UrbanWorkerApp/1.0'});
        if (fbRes.statusCode == 200) {
          final fbData = jsonDecode(fbRes.body) as List;
          if (fbData.isNotEmpty) {
            final lat = double.parse(fbData[0]['lat']);
            final lon = double.parse(fbData[0]['lon']);
            return LatLng(lat, lon);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In-App Road Navigation #${widget.bookingId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_customerPos != null) {
                final bounds = LatLngBounds.fromPoints([_workerPos, _customerPos!]);
                _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
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
              initialZoom: 14.5,
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
                      strokeWidth: 5.5,
                      color: const Color(0xFF1E88E5),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Worker position pin
                  Marker(
                    point: _workerPos,
                    width: 46,
                    height: 46,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
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

          // ─── TOP TURN-BY-TURN INSTRUCTION BANNER ───
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.turn_right_rounded, color: Colors.greenAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NEXT STEP', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(
                          _nextTurnInstruction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                          '${_distanceKm.toStringAsFixed(1)} KM • ~$_durationMins mins',
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
