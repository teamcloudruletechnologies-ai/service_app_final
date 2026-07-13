import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/catalog_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';
import '../config/api_config.dart';
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
  bool _isLocating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _detectLocation();
    });
  }

  void _loadData() {
    final catalog = context.read<CatalogProvider>();
    catalog.loadCategories();
    catalog.loadServices();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _currentAddress = 'Detecting location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Location services disabled';
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Location permission denied';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Location permission permanently denied';
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocode via OpenStreetMap Nominatim
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}'
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'com.urban.service_app',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null) {
          setState(() {
            _currentAddress = displayName;
          });
        } else {
          setState(() {
            _currentAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          });
        }
      } else {
        setState(() {
          _currentAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Failed to get location';
      });
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _showNearbyWorkers(ServiceItem service) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name first to complete setup'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait until we get your location, or re-detect it'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NearbyWorkersBottomSheet(
        service: service,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _currentAddress,
        userName: _nameCtrl.text.trim(),
        userEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final services = catalog.services.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.categoryName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    const zomatoColor = Color(0xFFE23744); // Zomato Red

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Zomato-style location & profile bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: zomatoColor, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _detectLocation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Current Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (_isLocating)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: zomatoColor,
                                  ),
                                )
                              else
                                const Icon(Icons.arrow_drop_down, color: zomatoColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Fields Section (Collapsible/Sleek card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Let\'s complete your profile 🚀',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your name to start',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: zomatoColor),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address (Optional)',
                            hintText: 'For sending billing invoices',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: zomatoColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Zomato style search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  onChanged: (v) {
                    setState(() {
                      _searchQuery = v;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search for home services, cleaning, repair...',
                    prefixIcon: Icon(Icons.search, color: zomatoColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Header for services list
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'WHAT ARE YOU LOOKING FOR?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Services Grid
            Expanded(
              child: catalog.loadingServices
                  ? const Center(child: CircularProgressIndicator(color: zomatoColor))
                  : services.isEmpty
                      ? Center(
                          child: Text(
                            'No services found matching "$_searchQuery"',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            final imageUrl = ApiConfig.resolveImageUrl(service.imageUrl);

                            return GestureDetector(
                              onTap: () => _showNearbyWorkers(service),
                              child: Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                                              errorBuilder: (_, __, ___) => Container(
                                                color: const Color(0xFFFEE2E2),
                                                child: const Icon(
                                                  Icons.home_repair_service,
                                                  color: zomatoColor,
                                                  size: 32,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFFFEE2E2),
                                              child: const Icon(
                                                Icons.home_repair_service,
                                                color: zomatoColor,
                                                size: 32,
                                              ),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${service.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: zomatoColor,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
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
}

class _NearbyWorkersBottomSheet extends StatefulWidget {
  const _NearbyWorkersBottomSheet({
    required this.service,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.userName,
    this.userEmail,
  });

  final ServiceItem service;
  final double latitude;
  final double longitude;
  final String address;
  final String userName;
  final String? userEmail;

  @override
  State<_NearbyWorkersBottomSheet> createState() => _NearbyWorkersBottomSheetState();
}

class _NearbyWorkersBottomSheetState extends State<_NearbyWorkersBottomSheet> {
  List<NearbyWorker> _workers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    try {
      final api = context.read<ApiService>();
      final result = await api.fetchNearbyWorkers(
        widget.latitude,
        widget.longitude,
        radius: 10.0,
        serviceType: widget.service.categoryName,
      );
      setState(() {
        _workers = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to find providers nearby: $e';
        _loading = false;
      });
    }
  }

  Future<void> _directBook(NearbyWorker? worker) async {
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();
      
      // Update profile first (Name, Email, Address, State)
      await auth.updateUserProfile(
        name: widget.userName,
        email: widget.userEmail,
        address: widget.address,
        state: 'Karnataka',
      );

      if (!mounted) return;
      
      // Create Booking directly (using DB Service Item Price)
      final booking = await context.read<BookingProvider>().createBooking(
            serviceId: widget.service.id,
            address: widget.address,
            workerId: worker?.id,
          );

      if (!mounted) return;

      if (booking != null) {
        // Success: Redirect straight to Payment Screen
        Navigator.pop(context); // Close bottom sheet
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking placed! Opening payment window...'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(booking: booking),
          ),
        );
      } else {
        setState(() {
          _error = auth.error ?? 'Failed to place booking';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Booking error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const zomatoColor = Color(0xFFE23744);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: FractionallySizedBox(
        heightFactor: 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Providers within limit for ${widget.service.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              'Location: ${widget.address}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: zomatoColor))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : _workers.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text(
                                  'No providers active in your location limit',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: zomatoColor,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _directBook(null),
                                  child: const Text('Book Anyway (System Auto-Assign)'),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: _workers.length,
                              itemBuilder: (context, index) {
                                final w = _workers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: Color(0xFFF3F4F6)),
                                  ),
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: zomatoColor.withOpacity(0.1),
                                          backgroundImage: (w.photoUrl != null && w.photoUrl!.isNotEmpty)
                                              ? NetworkImage(w.photoUrl!)
                                              : null,
                                          child: (w.photoUrl == null || w.photoUrl!.isEmpty)
                                              ? const Icon(Icons.person, color: zomatoColor)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                w.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    w.rating.toStringAsFixed(1),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${w.experienceYears} yrs exp',
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: zomatoColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _directBook(w),
                                          child: const Text('Book'),
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
}
