import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profile Fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedGender = 'Male';

  // Address & GPS Fields
  final _houseCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  double? _currentLat;
  double? _currentLng;
  bool _detectingLocation = false;
  bool _locationError = false;
  String _locationStatusMessage = 'Auto-detecting your GPS location...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.name != null && auth.user!.name.isNotEmpty) {
        _nameCtrl.text = auth.user!.name;
      }
      if (auth.user?.email != null) {
        _emailCtrl.text = auth.user!.email!;
      }

      final catalog = context.read<CatalogProvider>();
      catalog.loadCategories();
      catalog.loadServices();

      // Trigger automatic GPS location detection
      _detectGpsLocation();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _houseCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectGpsLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationError = false;
      _locationStatusMessage = 'Requesting GPS permission...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _detectingLocation = false;
          _locationError = true;
          _locationStatusMessage = 'GPS Location services are disabled. Please enable GPS on your device.';
        });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() {
          _detectingLocation = false;
          _locationError = true;
          _locationStatusMessage = 'Location permission denied. You can grant permission or fill address manually.';
        });
        return;
      }

      setState(() => _locationStatusMessage = 'Fetching GPS coordinates...');

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentLat = pos.latitude;
      _currentLng = pos.longitude;

      setState(() => _locationStatusMessage = 'Converting coordinates to address...');

      // Reverse geocoding via OpenStreetMap Nominatim API
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&addressdetails=1',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'UrbanServiceUserApp/1.0',
      }).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};

        final house = (addr['building'] ?? addr['house_number'] ?? addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? (data['display_name'] != null ? data['display_name'].toString().split(',').first : '')).toString();
        final area = addr['suburb'] ?? addr['neighbourhood'] ?? addr['village'] ?? addr['residential'] ?? '';
        final city = addr['city'] ?? addr['town'] ?? addr['municipality'] ?? addr['county'] ?? '';
        final district = addr['state_district'] ?? addr['county'] ?? city;
        final state = addr['state'] ?? '';
        final pincode = addr['postcode'] ?? '';

        setState(() {
          _houseCtrl.text = house.toString();
          _areaCtrl.text = area.toString();
          _cityCtrl.text = city.toString();
          _districtCtrl.text = district.toString();
          _stateCtrl.text = state.toString();
          _pincodeCtrl.text = pincode.toString();
          _detectingLocation = false;
          _locationError = false;
        });
      } else {
        setState(() {
          _detectingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('GPS Reverse Geocode Error: $e');
      setState(() {
        _detectingLocation = false;
        _locationError = true;
        _locationStatusMessage = 'GPS detection completed. You can adjust your address details below.';
      });
    }
  }

  Future<void> _saveProfileAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    final house = _houseCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final district = _districtCtrl.text.trim();
    final state = _stateCtrl.text.trim();
    final pincode = _pincodeCtrl.text.trim();

    final fullAddress = [house, area, city, district, state, pincode]
        .where((s) => s.isNotEmpty)
        .join(', ');

    // Save profile to backend & AuthProvider
    await auth.updateUserProfile(
      name: name,
      email: email.isNotEmpty ? email : null,
      state: state,
      address: fullAddress,
    );

    await auth.saveFullProfileLocation(
      lat: _currentLat ?? 13.0827,
      lng: _currentLng ?? 80.2707,
      houseVal: house,
      areaVal: area,
      cityVal: city,
      districtVal: district,
      stateVal: state,
      pincodeVal: pincode,
      fullAddr: fullAddress,
      genderVal: _selectedGender,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Profile Setup Completed! Welcome to Urban Service.'),
        backgroundColor: AppTheme.primary,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.accent,
                      child: Icon(Icons.person, size: 36, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Profile Setup',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Set up your details & GPS location to browse local service professionals.',
                            style: TextStyle(color: AppTheme.accent, fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Personal Details
              const Text(
                'Personal Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),

              // Full Name (Required)
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Rahul Sharma',
                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              // Gender Selection (Required)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gender *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Male', 'Female', 'Other'].map((g) {
                      final isSelected = _selectedGender == g;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = g),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                g,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Email (Optional)
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address (Optional)',
                  hintText: 'e.g. rahul@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Location & Address
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Address (GPS Auto-Detected)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                  ),
                  if (!_detectingLocation)
                    TextButton.icon(
                      onPressed: _detectGpsLocation,
                      icon: const Icon(Icons.my_location, size: 18, color: AppTheme.primary),
                      label: const Text('Re-detect', style: TextStyle(color: AppTheme.primary)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // GPS Status Banner
              if (_detectingLocation) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _locationStatusMessage,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (_locationError) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _locationStatusMessage,
                          style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _detectGpsLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Retry GPS', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Address Breakdown Text Fields (Auto-Filled + Editable)
              TextFormField(
                controller: _houseCtrl,
                decoration: InputDecoration(
                  labelText: 'House / Flat / Street',
                  hintText: 'e.g. Door No 45, MG Road',
                  prefixIcon: const Icon(Icons.home_outlined, color: AppTheme.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Area / Locality',
                        hintText: 'e.g. Anna Nagar',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City',
                        hintText: 'e.g. Chennai',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtCtrl,
                      decoration: InputDecoration(
                        labelText: 'District',
                        hintText: 'e.g. Chennai',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: InputDecoration(
                        labelText: 'State',
                        hintText: 'e.g. Tamil Nadu',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _pincodeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  hintText: 'e.g. 600040',
                  prefixIcon: const Icon(Icons.pin_drop_outlined, color: AppTheme.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 32),

              // Save & Continue Button
              ElevatedButton(
                onPressed: _saveProfileAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text(
                  'Continue to Home',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}