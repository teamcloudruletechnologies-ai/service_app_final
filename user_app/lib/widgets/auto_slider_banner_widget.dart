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
    _pageController = PageController(viewportFraction: 0.92, initialPage: 1000);
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
  void didUpdateWidget(covariant AutoSliderBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemCount = widget.banners.length;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % itemCount;
              });
            },
            itemBuilder: (context, index) {
              final actualIdx = index % itemCount;
              final banner = widget.banners[actualIdx];
              final imgUrl = ApiConfig.resolveImageUrl(banner.imageUrl);

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double pageOffset = 0.0;
                  if (_pageController.position.haveDimensions) {
                    pageOffset = (_pageController.page! - index);
                  }

                  // 3D vertical slide-up & backside stack effect
                  final double scale = (1 - (pageOffset.abs() * 0.08)).clamp(0.88, 1.0);
                  final double opacity = (1 - (pageOffset.abs() * 0.4)).clamp(0.2, 1.0);
                  final double translateY = pageOffset * -15;

                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: imgUrl.isNotEmpty
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => _buildFallbackBannerContent(
                                title: banner.title ?? 'Special Offer',
                                sub: 'Tap to view details',
                                action: 'Explore Now →',
                                accent: AppTheme.primary,
                                icon: Icons.campaign,
                              ),
                            )
                          : _buildFallbackBannerContent(
                              title: banner.title ?? 'Special Offer',
                              sub: 'Exclusive savings on home services',
                              action: 'Book Now →',
                              accent: AppTheme.primary,
                              icon: Icons.local_offer_outlined,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // ─── ANIMATED VERTICAL / HORIZONTAL INDICATOR DOTS ───
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(itemCount, (idx) {
            final isSelected = idx == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: isSelected ? 16 : 6,
              width: 6,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color(0xFF1E293B),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.15,
              child: Icon(icon, color: accent, size: 100),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  action,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
