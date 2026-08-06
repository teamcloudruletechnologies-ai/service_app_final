import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.service});

  final ServiceItem service;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  SubServiceItem? _selectedSubService;

  @override
  void initState() {
    super.initState();
    if (widget.service.subServices.isNotEmpty) {
      _selectedSubService = widget.service.subServices.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final address = user?.address ?? '';

    final hasSubServices = widget.service.subServices.isNotEmpty;
    final hasDescription = widget.service.description != null && widget.service.description!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── HERO IMAGE HEADER ───
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                          child: Container(
                            height: 260,
                            width: double.infinity,
                            color: const Color(0xFFEDF2F7),
                            child: CachedNetworkImage(
                              imageUrl: ApiConfig.resolveImageUrl(widget.service.imageUrl),
                              fit: BoxFit.cover,
                              errorWidget: (context, error, stackTrace) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: Icon(Icons.build_rounded, size: 64, color: AppTheme.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Top Gradient Shadow overlay for back button contrast
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Back Button
                        Positioned(
                          top: 48,
                          left: 20,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20),
                            ),
                          ),
                        ),
                        // Category Badge Overlay
                        if (widget.service.categoryName != null && widget.service.categoryName!.isNotEmpty)
                          Positioned(
                            top: 52,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                widget.service.categoryName!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // ─── MAIN CONTENT CONTAINER ───
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Name Title
                          Text(
                            widget.service.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // ─── DYNAMIC SERVICE PACKAGES (SUB-SERVICES) ───
                          if (hasSubServices) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Select Service Package',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF9C3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFEF08A)),
                                  ),
                                  child: Text(
                                    '${widget.service.subServices.length} Options Available',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF854D0E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.service.subServices.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, idx) {
                                final sub = widget.service.subServices[idx];
                                final hasSubImage = sub.imageUrl != null && sub.imageUrl!.trim().isNotEmpty;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedSubService = sub;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // ─── LEFT SIDE: Clean Rounded Image Box ───
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          width: 95,
                                          height: 95,
                                          color: const Color(0xFFF1F5F9),
                                          child: hasSubImage
                                              ? CachedNetworkImage(
                                                  imageUrl: ApiConfig.resolveImageUrl(sub.imageUrl),
                                                  fit: BoxFit.cover,
                                                  errorWidget: (context, error, stackTrace) => const Center(
                                                    child: Icon(Icons.build_rounded, size: 32, color: AppTheme.primary),
                                                  ),
                                                )
                                              : const Center(
                                                  child: Icon(Icons.build_rounded, size: 32, color: AppTheme.primary),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 24), // Moved text rightwards

                                      // ─── RIGHT SIDE: Sub Service Name & Price ───
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              sub.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                                letterSpacing: -0.3,
                                                height: 1.25,
                                              ),
                                            ),
                                            if (sub.price > 0 || widget.service.price > 0) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                '₹${(sub.price > 0 ? sub.price : widget.service.price).toInt()}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                            const SizedBox(height: 20),
                          ],

                          // ─── ABOUT SERVICE DESCRIPTION ───
                          if (hasDescription) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'About Service',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.service.description!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF475569),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── STICKY BOTTOM BOOK NOW BAR ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final customServiceItem = _selectedSubService != null
                        ? ServiceItem(
                            id: widget.service.id,
                            categoryId: widget.service.categoryId,
                            name: _selectedSubService!.name,
                            description: widget.service.description,
                            imageUrl: widget.service.imageUrl,
                            categoryName: widget.service.categoryName,
                            price: (_selectedSubService!.price > 0 ? _selectedSubService!.price : widget.service.price),
                            status: widget.service.status,
                            avgRating: widget.service.avgRating,
                            totalReviews: widget.service.totalReviews,
                            totalBookings: widget.service.totalBookings,
                            estimatedTime: _selectedSubService!.estimatedTime,
                            subServices: widget.service.subServices,
                          )
                        : widget.service;

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LocationPickerScreen(
                          service: customServiceItem,
                          initialAddress: address,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
