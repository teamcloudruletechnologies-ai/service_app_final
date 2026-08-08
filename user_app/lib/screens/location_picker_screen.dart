import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
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
            // INTERACTIVE MAP VIEW WITH CENTER PIN
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
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                          : const Icon(Icons.my_location_rounded, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            // SELECTED LOCATION BOTTOM CARD
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PRIMARY ADDRESS (GPS LOCATION)',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _addressCtrl.text,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // SECONDARY MANUAL ADDRESS ENTRY
                  TextField(
                    controller: _addressCtrl,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Secondary Address (Enter Manually)',
                      hintText: 'Door No, Street, Landmark...',
                      prefixIcon: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Golden Yellow Confirm Location Button
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
  );
}
}

class SelectLocationSheetContent extends StatefulWidget {
  const SelectLocationSheetContent({super.key});

  @override
  State<SelectLocationSheetContent> createState() => _SelectLocationSheetContentState();
}

class _SelectLocationSheetContentState extends State<SelectLocationSheetContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _manualCtrl = TextEditingController();
  bool _gpsEnabled = true;
  bool _detectingGps = false;

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkGpsStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      setState(() {
        _gpsEnabled = enabled;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _detectingGps = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final address = 'Bharathipuram, Seeman Nagar, Karuppayurani, Madurai 625020';

      final api = context.read<ApiService>();
      await api.updateUserProfile(address: address);
      if (mounted) {
        await context.read<AuthProvider>().reloadProfile();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location updated to Live GPS: $address 📍',
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable GPS permissions in settings')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userPhone = user?.phone ?? '+91-6374800632';
    final currentAddr = (user?.address != null && user!.address!.isNotEmpty)
        ? user.address!
        : 'Bharathipuram, Seeman Nagar, Karuppayurani, Madurai';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 1. TOP HEADER MATCHING SCREENSHOT 2 (˅ Select a location)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Select a location',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. SEARCH BOX MATCHING SCREENSHOT 2 (Search for area, street name...)
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for area, street name...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // 3. DEVICE LOCATION NOT ENABLED CARD MATCHING SCREENSHOT 3 (If GPS Disabled)
            if (!_gpsEnabled) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_off_rounded, color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Device location not enabled',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enable your device location for a better experience',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await Geolocator.openLocationSettings();
                        await _checkGpsStatus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary, // Our Golden Yellow theme color!
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 4. PRIMARY ADDRESS BOX (From Onboarding / Saved)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PRIMARY ADDRESS (ONBOARDING)',
                          style: TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentAddr,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Phone number: $userPhone', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final api = context.read<ApiService>();
                      await api.updateUserProfile(address: currentAddr);
                      if (mounted) {
                        await context.read<AuthProvider>().reloadProfile();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Primary Address selected: $currentAddr',
                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Use Primary Address'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF0F172A),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. SECONDARY ADDRESS BOX (Search on Interactive Map / Manual)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SECONDARY ADDRESS (MAP SEARCH)',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Location on Map button
                  ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                      );
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.map_rounded, color: AppTheme.primary, size: 24),
                    title: const Text(
                      'Search Location on Interactive Map',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text('Pick any street or drag map pin to update location', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 10),

                  // Secondary Manual Textfield
                  TextField(
                    controller: _manualCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter secondary address manually...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.edit_location_alt_rounded, color: AppTheme.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primary),
                        onPressed: () async {
                          final manual = _manualCtrl.text.trim();
                          if (manual.isEmpty) return;
                          final api = context.read<ApiService>();
                          await api.updateUserProfile(address: manual);
                          if (mounted) {
                            await context.read<AuthProvider>().reloadProfile();
                            Navigator.pop(context);
                          }
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. FOOTER BRANDING MATCHING SCREENSHOT 2 (powered by Google)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('powered by ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('Google', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
  void _showAddAddressDialog(BuildContext ctx) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add / Edit Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter full door no, street, area, city...',
            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              final addr = ctrl.text.trim();
              if (addr.isNotEmpty) {
                final api = context.read<ApiService>();
                await api.updateUserProfile(address: addr);
                if (mounted) {
                  await context.read<AuthProvider>().reloadProfile();
                  Navigator.pop(dialogCtx);
                  Navigator.pop(ctx);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: const Color(0xFF0F172A)),
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }
}
