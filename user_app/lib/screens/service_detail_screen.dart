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

  void _proceedToBooking(SubServiceItem? sub) {
    final user = context.read<AuthProvider>().user;
    final address = user?.address ?? '';
    final targetSub = sub ?? _selectedSubService;

    final customServiceItem = targetSub != null
        ? ServiceItem(
            id: widget.service.id,
            categoryId: widget.service.categoryId,
            name: targetSub.name.trim().isNotEmpty ? targetSub.name : widget.service.name,
            description: widget.service.description,
            imageUrl: (targetSub.imageUrl != null && targetSub.imageUrl!.trim().isNotEmpty)
                ? targetSub.imageUrl
                : widget.service.imageUrl,
            categoryName: widget.service.categoryName,
            price: (targetSub.price > 0 ? targetSub.price : widget.service.price),
            status: widget.service.status,
            avgRating: widget.service.avgRating,
            totalReviews: widget.service.totalReviews,
            totalBookings: widget.service.totalBookings,
            estimatedTime: targetSub.estimatedTime,
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
  }

  @override
  Widget build(BuildContext context) {
    final hasSubServices = widget.service.subServices.isNotEmpty;
    final hasDescription = widget.service.description != null && widget.service.description!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
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
                                  Colors.black.withOpacity(0.4),
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
                                color: Colors.white.withOpacity(0.95),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
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
                                color: Colors.black.withOpacity(0.65),
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Name Title
                          Text(
                            widget.service.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // ─── DYNAMIC SERVICE PACKAGES (SUB-SERVICES) ───
                          if (hasSubServices) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Select Service Package',
                                  style: TextStyle(
                                    fontSize: 15,
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
                            const SizedBox(height: 20),

                            ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.service.subServices.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 14),
                              itemBuilder: (context, idx) {
                                final sub = widget.service.subServices[idx];
                                final hasSubImage = sub.imageUrl != null && sub.imageUrl!.trim().isNotEmpty;
                                final hasName = sub.name.trim().isNotEmpty;
                                final hasPrice = sub.price > 0;
                                final imgPath = hasSubImage ? sub.imageUrl : widget.service.imageUrl;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedSubService = sub;
                                    });
                                    _proceedToBooking(sub);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 185,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        children: [
                                          // 1. FULL SIZE BANNER IMAGE (Always 185px height!)
                                          CachedNetworkImage(
                                            imageUrl: ApiConfig.resolveImageUrl(imgPath),
                                            width: double.infinity,
                                            height: 185,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.center,
                                            errorWidget: (context, error, stackTrace) => const Center(
                                              child: Icon(Icons.build_rounded, size: 36, color: AppTheme.primary),
                                            ),
                                          ),

                                          // 2. RIGHT DOWN SUB SERVICE OVERLAY BADGE (Without any background shadow on image!)
                                          if (hasName || hasPrice)
                                            Positioned(
                                              bottom: 12,
                                              right: 14,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.80),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white24, width: 0.8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (hasName)
                                                      Text(
                                                        sub.name,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13.5,
                                                          fontWeight: FontWeight.w800,
                                                          letterSpacing: -0.2,
                                                        ),
                                                      ),
                                                    if (hasName && hasPrice)
                                                      const Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                                        child: Text('•', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                                      ),
                                                    if (hasPrice)
                                                      Text(
                                                        '₹${sub.price.toInt()}',
                                                        style: const TextStyle(
                                                          color: AppTheme.primary,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w900,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
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
                                    color: Colors.black.withOpacity(0.03),
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
    );
  }
}
