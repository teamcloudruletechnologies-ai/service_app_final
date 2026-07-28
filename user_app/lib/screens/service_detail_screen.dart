import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'location_picker_screen.dart';
import 'nearby_workers_screen.dart';

/// Zomato-like service detail screen.
/// - If [address], [latitude], [longitude] are passed (from onboarding),
///   "Book Now" skips the location picker and goes straight to NearbyWorkers.
/// - If no location is passed (direct navigation), still asks for location.
class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    this.address,
    this.latitude,
    this.longitude,
    this.userName,
  });

  final int serviceId;
  // Pre-set location from onboarding (Zomato style — location already known)
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? userName;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceItem? _service;
  bool _loading = true;
  String? _error;
  final bool _booking = false;

  static const _red = Color(0xFF4A5343);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = await context.read<ApiService>().fetchService(widget.serviceId);
      if (mounted) setState(() => _service = service);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onBookNow() async {
    if (_service == null) return;

    // If location already set from onboarding → go directly to NearbyWorkers
    if (widget.address != null && widget.latitude != null && widget.longitude != null) {
      _goToNearbyWorkers(
        address: widget.address!,
        lat: widget.latitude!,
        lng: widget.longitude!,
        workers: const [], // will be fetched by NearbyWorkersScreen itself
        prefetched: false,
      );
      return;
    }

    // Else → open location picker first (when accessed without onboarding context)
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(serviceType: _service?.categoryName),
      ),
    );
    if (result != null && mounted) {
      _goToNearbyWorkers(
        address: result.address,
        lat: result.latitude ?? 0,
        lng: result.longitude ?? 0,
        workers: result.workers,
        prefetched: true,
      );
    }
  }

  void _goToNearbyWorkers({
    required String address,
    required double lat,
    required double lng,
    required List<NearbyWorker> workers,
    required bool prefetched,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NearbyWorkersScreen(
          service: _service!,
          address: address,
          latitude: lat,
          longitude: lng,
          workers: prefetched ? workers : null,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.address != null && widget.latitude != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_service?.name ?? 'Service Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildContent(_service!, hasLocation: hasLocation),
      bottomNavigationBar: _service == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show confirmed location (Zomato style) before book button
                    if (hasLocation)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: _red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Service at your location',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    widget.address!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Book Now button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _booking ? null : _onBookNow,
                        child: _booking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _service!.price > 0
                                    ? 'Book Now — ₹${_service!.price.toStringAsFixed(0)}'
                                    : 'Book Now',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContent(ServiceItem service, {required bool hasLocation}) {
    final imageUrl = ApiConfig.resolveImageUrl(service.imageUrl);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero image
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              imageUrl: imageUrl,
              errorWidget: (_, __, ___) => _placeholder(),
            )
          else
            _placeholder(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                if (service.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      service.categoryName!,
                      style: const TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),

                // Name
                Text(
                  service.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),

                const SizedBox(height: 12),

                // Rating row + Estimated time
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      service.avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (service.totalReviews > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${service.totalReviews} reviews)',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Container(width: 1, height: 16, color: Colors.grey.shade300),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${service.estimatedTime} min',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                  // Dynamic Inspection Price Note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3D0BA).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Price set after work inspection & invoice by partner',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 16),

                // About section
                const Text(
                  'About this service',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  service.description ?? 'Professional service delivered at your doorstep by verified experts.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 14),
                ),

                const SizedBox(height: 24),

                // Why book with us
                _buildWhySection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhySection() {
    const items = [
      (Icons.verified_user_outlined, 'Verified Professionals', 'Background-checked & trained experts'),
      (Icons.access_time_outlined, 'On-Time Service', 'Punctual and reliable every time'),
      (Icons.currency_rupee_outlined, 'Transparent Pricing', 'No hidden charges, ever'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why book with us?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.$1, color: _red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(item.$3, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: 220,
      color: _red.withValues(alpha: 0.07),
      child: const Center(
        child: Icon(Icons.home_repair_service, size: 64, color: _red),
      ),
    );
  }
}
