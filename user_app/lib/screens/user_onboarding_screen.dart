import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/catalog_provider.dart';
import '../services/api_service.dart';
import 'location_picker_screen.dart';
import 'payment_screen.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Location picked from the confirm-location screen
  String _currentAddress = 'Tap to set your location';
  double? _latitude;
  double? _longitude;
  bool _locationPicked = false;

  String _searchQuery = '';

  static const _red = Color(0xFFE23744);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadCategories();
      catalog.loadServices();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // Open the existing LocationPickerScreen to confirm location
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

  Future<void> _showNearbyWorkers(ServiceItem service) async {
    // Validate name first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name first'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Must have location
    if (!_locationPicked || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your location first (tap the location bar above)'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      _openLocationPicker();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NearbyWorkersSheet(
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
                          Text(
                            _currentAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: _locationPicked
                                  ? Colors.grey.shade700
                                  : _red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_locationPicked)
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

            // ─── USER NAME + EMAIL (below location) ───
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '👤 Complete your profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                            childAspectRatio: 0.82,
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                service.price > 0
                                                    ? '₹${service.price.toStringAsFixed(0)}'
                                                    : 'Free',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: service.price > 0 ? _red : Colors.green,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _red.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Book',
                                                  style: TextStyle(
                                                    color: _red,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
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

  Widget _servicePlaceholder() {
    return Container(
      color: const Color(0xFFFEE2E2),
      child: const Icon(Icons.home_repair_service, color: _red, size: 32),
    );
  }
}

// ─── NEARBY WORKERS BOTTOM SHEET ───

class _NearbyWorkersSheet extends StatefulWidget {
  const _NearbyWorkersSheet({
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
  State<_NearbyWorkersSheet> createState() => _NearbyWorkersSheetState();
}

class _NearbyWorkersSheetState extends State<_NearbyWorkersSheet> {
  List<NearbyWorker> _workers = [];
  bool _loading = true;
  bool _booking = false;
  String? _error;

  static const _red = Color(0xFFE23744);

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
      if (mounted) {
        setState(() {
          _workers = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load nearby workers';
          _loading = false;
        });
      }
    }
  }

  Future<void> _book(NearbyWorker? worker) async {
    if (_booking) return;
    setState(() => _booking = true);

    try {
      final auth = context.read<AuthProvider>();

      // 1. Save user profile
      await auth.updateUserProfile(
        name: widget.userName,
        email: widget.userEmail,
        address: widget.address,
      );

      if (!mounted) return;

      // 2. Create booking with the service's actual DB price
      final booking = await context.read<BookingProvider>().createBooking(
            serviceId: widget.service.id,
            address: widget.address,
            workerId: worker?.id,
          );

      if (!mounted) return;

      if (booking != null) {
        Navigator.pop(context); // close sheet
        // 3. Go straight to payment
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
        );
      } else {
        setState(() {
          _error = auth.error ?? 'Failed to place booking';
          _booking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Booking error: $e';
          _booking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          if (widget.service.price > 0)
                            Text(
                              '₹${widget.service.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: _red,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '${_workers.length} nearby',
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: _red, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 8),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _red))
                : _workers.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _workers.length,
                        itemBuilder: (context, i) => _buildWorkerCard(_workers[i]),
                      ),
          ),

          // Bottom: Book any worker CTA
          if (!_loading && !_booking)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: _red),
                ),
                onPressed: () => _book(null),
                child: const Text(
                  'Book Any Available Worker',
                  style: TextStyle(color: _red, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text(
          'No workers nearby (10km radius)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'We can still assign the next available worker',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _booking ? null : () => _book(null),
            child: _booking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm Booking Anyway'),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(NearbyWorker w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _red.withValues(alpha: 0.08),
            backgroundImage: (w.photoUrl?.isNotEmpty ?? false) ? NetworkImage(w.photoUrl!) : null,
            child: (w.photoUrl?.isEmpty ?? true)
                ? const Icon(Icons.person, color: _red)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 13),
                    const SizedBox(width: 2),
                    Text(
                      w.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${w.experienceYears} yrs • ${w.distance?.toStringAsFixed(1) ?? "—"} km',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _booking
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _red, strokeWidth: 2))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => _book(w),
                  child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
        ],
      ),
    );
  }
}
