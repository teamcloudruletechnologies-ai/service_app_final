import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'main_shell.dart';

class WorkerOnboardingScreen extends StatefulWidget {
  const WorkerOnboardingScreen({super.key});

  @override
  State<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();

  String? _selectedServiceType;

  final List<String> _serviceTypes = [
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Appliance Repair',
    'Painting',
    'Carpentry',
    'Pest Control'
  ];

  // Location variables
  String _currentAddress = 'Detecting location...';
  double? _latitude;
  double? _longitude;
  String? _city;
  String? _state;
  String? _pincode;
  bool _isLocating = false;
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectLocation();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isLocating = true;
      _currentAddress = 'Detecting location...';
    });

    try {
      final position = await _determinePosition();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationFetched = true;

        // Reverse geocode via OpenStreetMap Nominatim
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}'
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'com.urban.worker_app',
        });
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          final addressData = data['address'] as Map<String, dynamic>?;
          if (addressData != null) {
            _city = addressData['city'] ?? addressData['town'] ?? addressData['village'] ?? addressData['suburb'] ?? addressData['county'];
            _state = addressData['state'];
            _pincode = addressData['postcode'];
          }
          setState(() {
            _currentAddress = data['display_name'] ?? 'Coordinates: ${position.latitude}, ${position.longitude}';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentAddress = 'Location permissions required. Tap to retry.';
            _locationFetched = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (mounted && _latitude != null && _longitude != null) {
        setState(() {
          _currentAddress = 'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final serviceType = _selectedServiceType;
    final exp = int.tryParse(_experienceCtrl.text.trim()) ?? 0;

    if (serviceType == null || serviceType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service type')),
      );
      return;
    }

    if (!_locationFetched || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required. Please enable GPS and try again.')),
      );
      _autoDetectLocation();
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateWorkerProfile(
      name: name,
      email: email.isEmpty ? null : email,
      serviceType: serviceType,
      experienceYears: exp,
      city: _city,
      state: _state,
      address: _currentAddress,
      pincode: _pincode,
    );

    if (ok) {
      // Save geocoordinates to database
      await auth.updateWorkerLocation(_latitude!, _longitude!, pincode: _pincode);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Onboarding profile update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Partner Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join as Service Partner',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please fill in your basic details to start getting orders near your area.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // ─── LOCATION FETCH INDICATOR ───
                GestureDetector(
                  onTap: _autoDetectLocation,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF4A5343), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Service Area Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              _isLocating
                                  ? const SizedBox(
                                      height: 12,
                                      width: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4A5343)),
                                    )
                                  : Text(
                                      _currentAddress,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _locationFetched ? Colors.grey.shade700 : Colors.red,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        if (!_locationFetched && !_isLocating)
                          const Icon(Icons.refresh, color: Color(0xFF4A5343), size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailReg.hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Service Type
                DropdownButtonFormField<String>(
                  value: _selectedServiceType,
                  hint: const Text('Select Service Type'),
                  decoration: const InputDecoration(
                    labelText: 'Service Type / Skill',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: _serviceTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedServiceType = val;
                    });
                  },
                  validator: (v) => v == null ? 'Service type is required' : null,
                ),
                const SizedBox(height: 16),

                // Experience
                TextFormField(
                  controller: _experienceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    hintText: 'e.g. 5',
                    prefixIcon: Icon(Icons.timelapse_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Experience is required';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFF3F4F6),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
