import 'dart:async';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class AutoSliderBannerWidget extends StatefulWidget {
  const AutoSliderBannerWidget({super.key, required this.banners});

  final List<BannerItem> banners;

  @override
  State<AutoSliderBannerWidget> createState() => _AutoSliderBannerWidgetState();
}

class _AutoSliderBannerWidgetState extends State<AutoSliderBannerWidget> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9, initialPage: 1000);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFallbackBanners() {
    return [
      {
        'title': 'GOLD FLASH SALE',
        'subtitle': '₹1 for 3 months premium care',
        'action': 'Renew Gold now →',
        'colors': [const Color(0xFF0F0C08), const Color(0xFF261C14), const Color(0xFF0F0C08)],
        'accent': const Color(0xFFD4AF37),
        'icon': Icons.workspace_premium,
      },
      {
        'title': 'MONSOON CLEANING 30% OFF',
        'subtitle': 'Deep Home & Sofa Cleaning Services',
        'action': 'Book Service Now →',
        'colors': [const Color(0xFF0B2B26), const Color(0xFF163E38), const Color(0xFF051C18)],
        'accent': const Color(0xFF2EC4B6),
        'icon': Icons.cleaning_services_outlined,
      },
      {
        'title': 'EXPERT AC SERVICE & REPAIR',
        'subtitle': 'Flat ₹200 OFF on Gas Charging & Inspection',
        'action': 'Claim Discount →',
        'colors': [const Color(0xFF1D2A44), const Color(0xFF2B3A5A), const Color(0xFF101B33)],
        'accent': const Color(0xFF00B4D8),
        'icon': Icons.ac_unit_outlined,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasApiBanners = widget.banners.isNotEmpty;
    final fallbackBanners = _getFallbackBanners();
    final itemCount = hasApiBanners ? widget.banners.length : fallbackBanners.length;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % itemCount;
              });
            },
            itemBuilder: (context, index) {
              final actualIdx = index % itemCount;

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index);
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasApiBanners
                            ? [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)]
                            : fallbackBanners[actualIdx]['colors'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (hasApiBanners
                                ? Colors.white24
                                : (fallbackBanners[actualIdx]['accent'] as Color))
                            .withOpacity(0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: hasApiBanners
                        ? (widget.banners[actualIdx].imageUrl != null && widget.banners[actualIdx].imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  ApiConfig.resolveImageUrl(widget.banners[actualIdx].imageUrl!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => _buildFallbackBannerContent(
                                    title: widget.banners[actualIdx].title ?? 'Special Offer',
                                    sub: 'Tap to view details',
                                    action: 'Explore Now →',
                                    accent: AppTheme.primary,
                                    icon: Icons.campaign,
                                  ),
                                ),
                              )
                            : _buildFallbackBannerContent(
                                title: widget.banners[actualIdx].title ?? 'Special Offer',
                                sub: 'Exclusive savings on home services',
                                action: 'Book Now →',
                                accent: AppTheme.primary,
                                icon: Icons.local_offer_outlined,
                              ))
                        : _buildFallbackBannerContent(
                            title: fallbackBanners[actualIdx]['title'] as String,
                            sub: fallbackBanners[actualIdx]['subtitle'] as String,
                            action: fallbackBanners[actualIdx]['action'] as String,
                            accent: fallbackBanners[actualIdx]['accent'] as Color,
                            icon: fallbackBanners[actualIdx]['icon'] as IconData,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // ─── ANIMATED DOT INDICATORS ───
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(itemCount, (idx) {
            final isSelected = idx == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isSelected ? 20 : 6,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFallbackBannerContent({
    required String title,
    required String sub,
    required String action,
    required Color accent,
    required IconData icon,
  }) {
    return Stack(
      children: [
        Positioned(
          right: -10,
          top: -10,
          child: Opacity(
            opacity: 0.15,
            child: Icon(icon, color: accent, size: 90),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
