import 'dart:async' as async_timer;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/common_widgets.dart';
import 'service_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadBanners();
      catalog.loadServices();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    context.read<CatalogProvider>().loadServices(
          categoryId: context.read<CatalogProvider>().selectedCategoryId,
          search: query,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3), // Crisp Milk White
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${auth.user?.name.split(' ').first ?? 'User'} 👋',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -1.0,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find trusted professionals near you',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  cursorColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4A5343)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onSubmitted: _search,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: BannerCarousel(
                banners: catalog.banners,
                loading: catalog.loadingBanners,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: catalog.loadingServices
                ? const SliverFillRemaining(child: LoadingView(message: 'Loading services...'))
                : catalog.error != null
                    ? SliverFillRemaining(
                        child: ErrorView(
                          message: catalog.error!,
                          onRetry: () {
                            catalog.loadCategories();
                            catalog.loadServices();
                          },
                        ),
                      )
                    : catalog.services.isEmpty
                        ? const SliverFillRemaining(
                            child: Center(child: Text('No services available')),
                          )
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final service = catalog.services[index];
                                return ServiceCard(
                                  service: service,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ServiceDetailScreen(serviceId: service.id),
                                    ),
                                  ),
                                );
                              },
                              childCount: catalog.services.length,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class BannerCarousel extends StatefulWidget {
  final List<BannerItem> banners;
  final bool loading;

  const BannerCarousel({
    super.key,
    required this.banners,
    required this.loading,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  async_timer.Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92, initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = async_timer.Timer.periodic(const Duration(seconds: 4), (timer) {
      if (widget.banners.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.banners.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A5343)),
        ),
      );
    }

    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final imageUrl = ApiConfig.resolveImageUrl(banner.imageUrl);

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.08)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 160,
                      width: Curves.easeOut.transform(value) * MediaQuery.sizeOf(context).width,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrl.isNotEmpty
                            ? (imageUrl.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(imageUrl.split(',').last),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFE5E7EB),
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A5343)),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: const Color(0xFFE5E7EB),
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  ))
                            : Container(color: Colors.grey.shade200),
                        if (banner.title != null && banner.title!.isNotEmpty)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.0),
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (banner.title != null && banner.title!.isNotEmpty)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 14,
                            child: Text(
                              banner.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
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
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentPage == index ? 16 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF4A5343)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
