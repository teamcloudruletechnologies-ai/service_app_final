import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
    '🏠 Home Maintenance',
    '❄️ Appliance Services',
    '💄 Beauty & Wellness',
    '🧼 Cleaning',
    '🔧 Plumbing',
    '⚡ Electrical',
    '📹 Security & CCTV',
  ];

  List<String> _getServicesForCategory(String categoryName) {
    final cleanName = categoryName.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim().toLowerCase();
    
    if (cleanName.contains('clean')) {
      return [
        'Full Home Deep Clean',
        'Kitchen Deep Clean & Degreasing',
        'Bathroom Cleaning & Sanitization',
        'Sofa & Carpet Dry Cleaning',
        'Window & Glass Cleaning',
        'Balcony & Floor Scrubbing',
      ];
    } else if (cleanName.contains('appliance')) {
      return [
        'AC Service, Gas Charge & Repair',
        'Washing Machine Repair',
        'Refrigerator / Fridge Repair',
        'Water Purifier / RO Service',
        'Microwave & Oven Repair',
        'TV Wall Mount & Repair',
      ];
    } else if (cleanName.contains('beauty') || cleanName.contains('wellness')) {
      return [
        'Salon & Spa Treatments',
        'Haircut & Hair Styling',
        'Facial, Waxing & Threading',
        'Manicure & Pedicure',
        'Bridal & Party Makeup',
      ];
    } else if (cleanName.contains('security') || cleanName.contains('cctv')) {
      return [
        'CCTV Camera Installation & Setup',
        'Security Alarm & Sensor Fitting',
        'Biometric Lock Installation',
        'DVR / NVR Configuration & Cabling',
      ];
    } else if (cleanName.contains('plumb')) {
      return [
        'Tap Fitting & Leakage Fix',
        'Toilet & Commode Unblocking',
        'Drain & Pipe Cleaning',
        'Water Tank Cleaning',
        'Motor Pump Repair & Fitting',
        'Basin & Sink Fitting',
      ];
    } else if (cleanName.contains('electr')) {
      return [
        'Fan, Switch & Socket Installation',
        'MCB & Fuse Box Repair',
        'Light & Chandelier Fitting',
        'House Wiring & Short Circuit Fix',
        'Inverter Installation & Repair',
      ];
    } else {
      return [
        'Furniture Repair & Assembly',
        'Door Lock & Latch Fitting',
        'Full Home Wall Painting',
        'Wall Drilling & Frame Hanging',
        'Wooden Cabinet & Wardrobe Fix',
        'General Handyman & Maintenance',
      ];
    }
  }

  // Location variables
  String _currentAddress = 'Detecting location...';
  double? _latitude;
  double? _longitude;
  String? _city;
  String? _state;
  String? _pincode;
  bool _isLocating = false;
  bool _locationFetched = false;

  // DB Categories & Services
  List<ServiceCategory> _dbCategories = [];
  final Map<int, List<ServiceItem>> _categoryServicesMap = {};
  final Set<String> _selectedServices = {};

  List<String> get categoryOptions {
    if (_dbCategories.isNotEmpty) {
      return _dbCategories.map((c) => c.name).toList();
    }
    return _serviceTypes;
  }

  List<String> _getServicesListForCategory(String categoryName) {
    final cleanCategory = categoryName.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim().toLowerCase();
    
    // Check if matching DB category exists
    final dbCat = _dbCategories.firstWhere(
      (c) => c.name.toLowerCase().contains(cleanCategory) || cleanCategory.contains(c.name.toLowerCase()),
      orElse: () => const ServiceCategory(id: -1, name: '', status: ''),
    );

    if (dbCat.id != -1 && _categoryServicesMap.containsKey(dbCat.id)) {
      final dbServices = _categoryServicesMap[dbCat.id]!.map((s) => s.name).toList();
      if (dbServices.isNotEmpty) return dbServices;
    }

    // Fallback static services mapping
    return _getServicesForCategory(categoryName);
  }

  void _onCategoryChanged(String? val) {
    setState(() {
      _selectedServiceType = val;
      _selectedServices.clear();
      if (val != null) {
        // By default select all services under this category
        final services = _getServicesListForCategory(val);
        _selectedServices.addAll(services);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectLocation();
    });
  }

  Future<void> _fetchCategoriesAndServices() async {
    if (!mounted) return;
    try {
      final api = context.read<ApiService>();
      final pagedCats = await api.fetchCategories();
      final pagedServs = await api.fetchServices();

      if (mounted) {
        setState(() {
          _dbCategories = pagedCats.items;
          _categoryServicesMap.clear();
          for (final service in pagedServs.items) {
            if (service.categoryId != null) {
              _categoryServicesMap.putIfAbsent(service.categoryId!, () => []).add(service);
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  void _showLocationDialog({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off_rounded, color: Colors.amber, size: 36),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationDialog(
          title: 'GPS Location Disabled',
          message: 'GPS location services are turned off on your device. Turn on GPS to auto-detect your location.',
          actionLabel: 'Turn On GPS',
          onAction: () => Geolocator.openLocationSettings(),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showLocationDialog(
            title: 'Location Permission Required',
            message: 'Location permission is required to auto-detect your location.',
            actionLabel: 'Open Settings',
            onAction: () => Geolocator.openAppSettings(),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showLocationDialog(
          title: 'Location Permission Denied',
          message: 'Location permissions are permanently denied. Please enable them in app settings.',
          actionLabel: 'Open Settings',
          onAction: () => Geolocator.openAppSettings(),
        );
      }
      return null;
    }

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
        const SnackBar(content: Text('Please select a Category Type')),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service you offer')),
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

                // Category Type Dropdown (Fetched from DB)
                DropdownButtonFormField<String>(
                  value: _selectedServiceType,
                  hint: const Text('Select Category'),
                  decoration: const InputDecoration(
                    labelText: 'Category Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categoryOptions.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: _onCategoryChanged,
                  validator: (v) => v == null ? 'Category type is required' : null,
                ),
                if (_selectedServiceType != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select services you offer under $_selectedServiceType:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap chips to select or unselect services you provide:',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getServicesListForCategory(_selectedServiceType!).map((service) {
                            final isSelected = _selectedServices.contains(service);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedServices.remove(service);
                                  } else {
                                    _selectedServices.add(service);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFEF3C7) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.add_circle_outline,
                                      size: 14,
                                      color: isSelected ? const Color(0xFFD97706) : const Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      service,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF92400E) : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    backgroundColor: AppTheme.olive,
                    foregroundColor: AppTheme.matteBlack,
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
                            color: AppTheme.matteBlack,
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
