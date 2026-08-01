import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'nearby_workers_screen.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.service, this.initialAddress});

  final ServiceItem? service;
  final String? initialAddress;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default coordinates (Madurai, Tamil Nadu)
  LatLng _selectedCenter = const LatLng(9.9252, 78.1198);
  final MapController _mapCtrl = MapController();
  final TextEditingController _addressCtrl = TextEditingController();
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _addressCtrl.text = widget.initialAddress ?? 'Anna Nagar, Madurai, Tamil Nadu 625020';
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  void _showLocationDialog({required String title, required String message, required VoidCallback onAction, required String actionLabel}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppTheme.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationDialog(
            title: 'GPS Location Disabled',
            message: 'Please turn on GPS location services to detect your delivery location.',
            onAction: () => Geolocator.openLocationSettings(),
            actionLabel: 'Turn On GPS',
          );
        }
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showLocationDialog(
              title: 'Permission Required',
              message: 'Location permission is required to detect your location on map.',
              onAction: () => Geolocator.requestPermission(),
              actionLabel: 'Grant Permission',
            );
          }
          setState(() => _loadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationDialog(
            title: 'Permission Denied Permanently',
            message: 'Location permission is permanently denied. Please enable it in Settings.',
            onAction: () => Geolocator.openAppSettings(),
            actionLabel: 'Open Settings',
          );
        }
        setState(() => _loadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedCenter = newPos;
        _loadingLocation = false;
      });

      _mapCtrl.move(newPos, 15.0);
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _onConfirm() {
    final user = context.read<AuthProvider>().user;
    final finalAddress = _addressCtrl.text.trim().isEmpty ? 'Anna Nagar, Madurai, Tamil Nadu 625020' : _addressCtrl.text.trim();

    if (widget.service != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NearbyWorkersScreen(
            service: widget.service!,
            address: finalAddress,
            latitude: _selectedCenter.latitude,
            longitude: _selectedCenter.longitude,
            userName: user?.name,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop(finalAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm Your Location', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // INTERACTIVE MAP VIEW WITH CENTER PIN (Screen 8 Mockup)
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _selectedCenter,
                      initialZoom: 15.0,
                      onPositionChanged: (pos, hasGesture) {
                        if (hasGesture && pos.center != null) {
                          setState(() {
                            _selectedCenter = pos.center!;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.urbanservice.user',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selectedCenter,
                            radius: 80,
                            useRadiusInMeter: true,
                            color: Colors.blue.withValues(alpha: 0.18),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Center Location Pin Indicator
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 30),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 48,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  // GPS Location Fab Floating Button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      onPressed: _loadingLocation ? null : _getCurrentLocation,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      child: _loadingLocation
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                          : const Icon(Icons.my_location_rounded, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            // SELECTED LOCATION BOTTOM CARD (Screen 8 Mockup)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(fontSize: 13, color: Color(0xFF718096), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _addressCtrl.text,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Allow editing address
                        },
                        child: const Text('Change', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Golden Yellow Confirm Location Button (Screen 8 Mockup)
                  ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF1A1A1A),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
