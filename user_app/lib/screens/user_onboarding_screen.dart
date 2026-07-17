import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';
import 'nearby_workers_screen.dart';
import 'main_shell.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _currentAddress = 'Detecting location...';
  double? _latitude;
  double? _longitude;
  bool _locationPicked = false;
  bool _isLocating = false;
  String _searchQuery = '';

  static const _red = Color(0xFF4A5343);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadCategories();
      catalog.loadServices();
      _autoDetectLocation();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isLocating = true;
      _currentAddress = 'Detecting location...';
    });

    final position = await _determinePosition();
    if (position != null) {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationPicked = true;

      // Reverse geocode via OpenStreetMap Nominatim
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}'
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'com.urban.service_app',
        });
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          final displayName = data['display_name'] as String?;
          if (displayName != null) {
            setState(() {
              _currentAddress = displayName;
            });
          }
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
        if (mounted) {
          setState(() {
            _currentAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _currentAddress = 'Location permission required. Tap to set.';
          _locationPicked = false;
        });
      }
    }

    if (mounted) {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _currentAddress = result.address;
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationPicked = true;
      });
    }
  }

  Future<bool> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    if (!_locationPicked || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your location first'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      await _openLocationPicker();
      return false;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.updateUserProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      address: _currentAddress,
    );

    if (success) {
      await auth.saveLocationCoordinates(_latitude!, _longitude!);
      return true;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Failed to save profile. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _saveAndProceed() async {
    final success = await _saveProfileData();
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  Future<void> _navigateToService(ServiceItem service) async {
    final success = await _saveProfileData();
    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NearbyWorkersScreen(
            service: service,
            address: _currentAddress,
            latitude: _latitude!,
            longitude: _longitude!,
            userName: _nameCtrl.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final services = catalog.services.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.categoryName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── LOCATION BAR (Zomato-style top-left) ───
            GestureDetector(
              onTap: _openLocationPicker,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: _red, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _locationPicked ? 'Your Location' : 'Set Location',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: _red, size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          _isLocating
                              ? const SizedBox(
                                  height: 12,
                                  width: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: _red),
                                )
                              : Text(
                                  _currentAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _locationPicked ? Colors.grey.shade700 : _red,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    if (!_locationPicked && !_isLocating)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Set →',
                          style: TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ─── PROFILE FORM CARD ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '👤 Setup your Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _red),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Email (optional)',
                            hintText: 'For billing invoices',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _saveAndProceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Save & Get Started', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ─── SEARCH BAR ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search services, plumbing, cleaning...',
                    hintStyle: TextStyle(fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: _red, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ─── SECTION HEADER ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'WHAT ARE YOU LOOKING FOR?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ─── SERVICES GRID ───
            Expanded(
              child: catalog.loadingServices
                  ? const Center(child: CircularProgressIndicator(color: _red))
                  : services.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.home_repair_service, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No services available'
                                    : 'No services match "$_searchQuery"',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.05, // Adjusted to fit nicely without a button row
                          ),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            final imageUrl = ApiConfig.resolveImageUrl(service.imageUrl);

                            return GestureDetector(
                              onTap: () => _navigateToService(service),
                              child: Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _servicePlaceholder(),
                                            )
                                          : _servicePlaceholder(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        service.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicePlaceholder() {
    return Container(
      color: const Color(0xFFFEE2E2),
      child: const Icon(Icons.home_repair_service, color: _red, size: 32),
    );
  }
}