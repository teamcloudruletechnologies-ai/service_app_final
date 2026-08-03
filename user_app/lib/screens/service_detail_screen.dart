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

    final inclusions = [
      'Verified Expert Technicians',
      '30-Day Service Guarantee',
      'Genuine Spare Parts & Tools',
      'Post-service Cleaning & Inspection',
    ];

    final effectivePrice = (_selectedSubService != null && _selectedSubService!.price > 0)
        ? _selectedSubService!.price
        : widget.service.price;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Banner Image with Back Arrow Button
                    Stack(
                      children: [
                        Container(
                          height: 250,
                          width: double.infinity,
                          color: const Color(0xFFEDF2F7),
                          child: CachedNetworkImage(
                            imageUrl: ApiConfig.resolveImageUrl(widget.service.imageUrl),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.build_rounded, size: 64, color: AppTheme.primary),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 44,
                          left: 16,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A), size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Title & Rating Badge
                          Text(
                            widget.service.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: const [
                              Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                '4.8 ',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A)),
                              ),
                              Text(
                                '(1.4k reviews)',
                                style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),

                          // SUB-SERVICES / PACKAGES SELECTION SECTION
                          if (widget.service.subServices.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Select Service Package',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${widget.service.subServices.length} Options Available',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.service.subServices.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final sub = widget.service.subServices[idx];
                                final isSelected = _selectedSubService?.id == sub.id || (_selectedSubService == null && idx == 0);

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedSubService = sub;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: AppTheme.primary.withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Radio<dynamic>(
                                          value: sub.id,
                                          groupValue: _selectedSubService?.id ?? widget.service.subServices.first.id,
                                          activeColor: AppTheme.primary,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedSubService = sub;
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sub.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                                  color: const Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${sub.estimatedTime} mins',
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '₹${((sub.price > 0 ? sub.price : widget.service.price)).toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: isSelected ? AppTheme.primaryDark : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 16),
                          ],

                          // About Service Description
                          const Text(
                            'About Service',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.service.description ??
                                'Professional service for your home. Verified expert technicians with post-service inspection guarantee.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A5568),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // What's Included Checkmarks List
                          const Text(
                            "What's Included",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 14),

                          ...inclusions.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF1A1A1A)),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Book Now Bar with Price Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      Text(
                        '₹${effectivePrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Pass selected sub-service package details to location picker / booking flow
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
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
