import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final address = user?.address ?? '';

    final inclusions = [
      'Tap & Pipe Repair',
      'Leakage Fix',
      'Bathroom Fitting',
      'And more...',
    ];

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
                    // Top Hero Banner Image with Back Arrow Button (Screen 7 Mockup)
                    Stack(
                      children: [
                        Container(
                          height: 250,
                          width: double.infinity,
                          color: const Color(0xFFEDF2F7),
                          child: CachedNetworkImage(
                            imageUrl: ApiConfig.getUploadUrl(service.imageUrl),
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
                          // Service Title & Rating Badge (Screen 7 Mockup)
                          Text(
                            service.name,
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
                                '4.7 ',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A)),
                              ),
                              Text(
                                '(1.2k reviews)',
                                style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),

                          // About Service Description (Screen 7 Mockup)
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
                            service.description ??
                                'Professional plumbing services for your home. We fix leaks, taps, pipes & more with verified expert technicians.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A5568),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // What's Included Checkmarks List (Screen 7 Mockup)
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

            // Sticky Bottom Golden Yellow Book Now Button (Screen 7 Mockup)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LocationPickerScreen(
                        service: service,
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
    );
  }
}
